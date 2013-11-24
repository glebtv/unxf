## UnXF - Un-X-Forward* the Rack environment

Rack middleware to remove "HTTP_X_FORWARDED_FOR" or "HTTP_X_REAL_IP" in the Rack environment and replace "REMOTE_ADDR" with the value of the original client address.

This uses the "rpatricia" RubyGem to filter out spoofed requests from clients outside your LAN.  The list of trusted address defaults to private LAN addresses defined RFC 1918 and those belonging to localhost.

This will also read "HTTP_X_FORWARDED_PROTO" and set "rack.url_scheme" to "https" if the "X-Forwarded-Proto" header is set properly and sent from a trusted address chain.

## Installation

Add this line to your application's Gemfile:

    gem 'glebtv-unxf'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install glebtv-unxf

## Credits

Forked from: http://repo.or.cz/w/unxf.git

GPLv2 licensed
