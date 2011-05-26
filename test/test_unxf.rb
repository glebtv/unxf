require "test/unit"
require "logger"
require "stringio"
require "rack"
require "rack/lobster"
require "unxf"

class TestUnXF < Test::Unit::TestCase

  def setup
    @env = nil
    @io = StringIO.new
    @req = { "rack.logger" => Logger.new(@io) }
    app = lambda { |env| @env = env; [ 200, {}, [] ] }
    @app = Rack::ContentLength.new(Rack::ContentType.new(app, 'text/plain'))
  end

  def test_single_proxy
    req = Rack::MockRequest.new(UnXF.new(@app))
    env = {
      "HTTP_X_FORWARDED_FOR" => "0.6.6.6",
      "REMOTE_ADDR" => "127.0.0.1",
    }
    r = req.get("http://example.com/", @req.merge(env))
    assert_equal 200, r.status.to_i
    assert_equal "0.6.6.6", @env["REMOTE_ADDR"]
    assert ! @env.key?("HTTP_X_FORWARDED_FOR")
  end

  def test_multiple_proxies
    req = Rack::MockRequest.new(UnXF.new(@app))
    env = {
      "HTTP_X_FORWARDED_FOR" => "0.6.6.6,192.168.1.1",
      "REMOTE_ADDR" => "127.0.0.1",
    }
    r = req.get("http://example.com/", @req.merge(env))
    assert_equal "0.6.6.6", @env["REMOTE_ADDR"]
    assert_equal 200, r.status.to_i
    assert ! @env.key?("HTTP_X_FORWARDED_FOR")
  end

  def test_spoofed
    req = Rack::MockRequest.new(UnXF.new(@app))
    env = {
      "HTTP_X_FORWARDED_FOR" => "0.6.6.6",
      "REMOTE_ADDR" => "227.0.0.1",
    }
    r = req.get("http://example.com/", @req.merge(env))
    assert_equal "227.0.0.1", @env["REMOTE_ADDR"]
    assert_equal r.status.to_i, 200
  end

  def test_trusted_chain
    req = Rack::MockRequest.new(UnXF.new(@app))
    env = {
      "HTTP_X_FORWARDED_FOR" => "0.6.6.6,192.168.0.1",
      "REMOTE_ADDR" => "127.0.0.1",
    }
    r = req.get("http://example.com/", @req.merge(env))
    assert_equal 200, r.status.to_i
    assert_equal "0.6.6.6", @env["REMOTE_ADDR"]
    assert ! @env.key?("HTTP_X_FORWARDED_FOR")
  end

  def test_spoofed_in_chain
    req = Rack::MockRequest.new(UnXF.new(@app))
    env = {
      "HTTP_X_FORWARDED_FOR" => "0.6.6.6,8.8.8.8",
      "REMOTE_ADDR" => "127.0.0.1",
    }
    r = req.get("http://example.com/", @req.merge(env))
    assert_equal "127.0.0.1", @env["REMOTE_ADDR"]
    assert_equal r.status.to_i, 200
  end

  def test_spoofed_null_safe
    req = Rack::MockRequest.new(UnXF.new(@app))
    env = {
      "HTTP_X_FORWARDED_FOR" => "\0.6.6.6,8.8.8.8",
      "REMOTE_ADDR" => "127.0.0.1",
    }
    r = req.get("http://example.com/", @req.merge(env))
    assert_equal "127.0.0.1", @env["REMOTE_ADDR"]
    assert_equal r.status.to_i, 200
  end

  def test_more_trust
    req = Rack::MockRequest.new(UnXF.new(@app, [ :LOCALHOST, "0.6.6.6" ]))
    env = {
      "HTTP_X_FORWARDED_FOR" => "1.6.6.6,0.6.6.6",
      "REMOTE_ADDR" => "127.0.0.1",
    }
    r = req.get("http://example.com/", @req.merge(env))
    assert_equal r.status.to_i, 200
    assert_equal "1.6.6.6", @env["REMOTE_ADDR"]
    assert ! @env.key?("HTTP_X_FORWARDED_FOR")
  end

  def test_one_trusted
    req = Rack::MockRequest.new(UnXF.new(@app, "0.6.6.6"))
    env = {
      "HTTP_X_FORWARDED_FOR" => "1.6.6.6",
      "REMOTE_ADDR" => "0.6.6.6",
    }
    r = req.get("http://example.com/", @req.merge(env))
    assert_equal r.status.to_i, 200
    assert_equal "1.6.6.6", @env["REMOTE_ADDR"]
    assert ! @env.key?("HTTP_X_FORWARDED_FOR")
  end
end
