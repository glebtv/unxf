Gem::Specification.new do |s|
  s.name = "glebtv-unxf"
  s.version = '2.1.0'
  s.homepage = 'https://github.com/glebtv/unxf'
  s.authors = ["UnXF hackers"]
  s.date = Time.now.utc.strftime('%Y-%m-%d')
  s.description = 'Rack middleware to remove "HTTP_X_FORWARDED_FOR" or "HTTP_X_REAL_IP" in the Rack environment and replace "REMOTE_ADDR" with the value of the original client address.'
  s.email = %q{unxf@librelist.org}

  s.summary = "unxf"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('rack', '>= 1.1')
  s.add_dependency('rpatricia', '~> 1.0')
  s.add_development_dependency('wrongdoc', '~> 1.5')

  s.licenses = ['GPL']
end
