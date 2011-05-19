# -*- encoding: binary -*-
require 'rpatricia'

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

  def initialize(app, trusted = [:RFC_1918, :LOCALHOST])
    @app = app
    @trusted = Patricia.new
    Array(trusted).each do |mask|
      mask = UnXF.const_get(mask) if Symbol === mask
      Array(mask).each { |m| @trusted.add(m, true) }
    end
  end

  def call(env)
    if xff_str = env.delete(HTTP_X_FORWARDED_FOR)
      xff = xff_str.split(/\s*,\s*/)
      addr = env[REMOTE_ADDR]
      begin
        while @trusted.include?(addr) && tmp = xff.pop
          addr = tmp
        end
      rescue ArgumentError
        return on_bad_addr(env, xff_str)
      end

      env[REMOTE_ADDR] = addr

      # it's stupid to have https at any point other than the first
      # proxy in the chain, so we don't support that
      if xff.empty?
        env.delete(HTTP_X_FORWARDED_PROTO) =~ /\Ahttps\b/ and
                                             env[RACK_URL_SCHEME] = HTTPS
      else
        return on_bad_addr(env, xff_str)
      end
    end
    @app.call(env)
  end

  # Our default action on a bad address is to just continue dispatching
  # the application with the existing environment
  # You may extend this object to override this error
  def on_bad_addr(env, xff_str)
    # be sure to inspect xff_str to escape it, control characters may be
    # present in the HTTP headers may appear in the header value and
    # used to exploit anyone who opens the log file.  nginx doesn't
    # filter/reject control characters, nor does Mongrel...
    env["rack.logger"].error(
                    "bad XFF #{xff_str.inspect} from #{env[REMOTE_ADDR]}")
    [ 400, [ %w(Content-Length 0), %w(Content-Type text/html) ], [] ]
  end
end
