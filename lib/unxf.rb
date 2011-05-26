# -*- encoding: binary -*-
require 'rpatricia'

# Rack middleware to remove "HTTP_X_FORWARDED_FOR" in the Rack environment and
# replace "REMOTE_ADDR" with the value of the original client address.
class UnXF
  # :stopdoc:
  # reduce garbage overhead by using constant strings
  REMOTE_ADDR = "REMOTE_ADDR".freeze
  HTTP_X_FORWARDED_FOR = "HTTP_X_FORWARDED_FOR"
  HTTP_X_FORWARDED_PROTO = "HTTP_X_FORWARDED_PROTO"
  RACK_URL_SCHEME = "rack.url_scheme".freeze
  HTTPS = "https"
  # :startdoc:

  # local LAN addresses described in RFC 1918
  RFC_1918 = %w(10.0.0.0/8 172.16.0.0/12 192.168.0.0/16)

  # localhost addresses (127.0.0.0/8)
  LOCALHOST = %w(127.0.0.0/8)

  # In your Rack config.ru:
  #
  #   use UnXF
  #
  # If you do not want to trust any hosts other than "0.6.6.6",
  # you may only specify one host to trust:
  #
  #   use UnXF, "0.6.6.6"
  #
  # If you want to trust "0.6.6.6" in addition to the default set of hosts:
  #
  #   use UnXF, [ :RFC_1918, :LOCALHOST, "0.6.6.6" ]
  #
  def initialize(app, trusted = [:RFC_1918, :LOCALHOST])
    @app = app
    @trusted = Patricia.new
    Array(trusted).each do |mask|
      mask = UnXF.const_get(mask) if Symbol === mask
      Array(mask).each { |m| @trusted.add(m, true) }
    end
  end

  # Rack entry point
  def call(env) # :nodoc:
    unxf!(env) || @app.call(env)
  end

  # returns +nil+ on success and a Rack response triplet on failure
  # This allows existing applications to use UnXF without putting it
  # into the middleware stack (to avoid increasing stack depth and GC time)
  def unxf!(env)
    if xff_str = env.delete(HTTP_X_FORWARDED_FOR)
      xff = xff_str.split(/\s*,\s*/)
      addr = env[REMOTE_ADDR]
      begin
        while @trusted.include?(addr) && tmp = xff.pop
          addr = tmp
        end
      rescue ArgumentError
        return on_broken_addr(env, xff_str)
      end

      # it's stupid to have https at any point other than the first
      # proxy in the chain, so we don't support that
      if xff.empty?
        env[REMOTE_ADDR] = addr
        env.delete(HTTP_X_FORWARDED_PROTO) =~ /\Ahttps\b/ and
                                             env[RACK_URL_SCHEME] = HTTPS
      else
        return on_untrusted_addr(env, xff_str)
      end
    end
    nil
  end

  # Our default action on a broken address is to just fall back to calling
  # the app without modifying the env
  def on_broken_addr(env, xff_str)
    @app.call(env)
  end

  # Our default action on an untrusted address is to just fall back to calling
  # the app without modifying the env
  def on_untrusted_addr(env, xff_str)
    @app.call(env)
  end
end
