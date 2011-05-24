ENV["VERSION"] or abort "VERSION= must be specified"
manifest = File.readlines('.manifest').map! { |x| x.chomp! }
test_files = manifest.grep(%r{\Atest/test_.*\.rb\z})
require 'wrongdoc'
extend Wrongdoc::Gemspec
name, summary, title = readme_metadata

Gem::Specification.new do |s|
  s.name = %q{unxf}
  s.version = ENV["VERSION"].dup
  s.homepage = Wrongdoc.config[:rdoc_url]
  s.authors = ["#{name} hackers"]
  s.date = Time.now.utc.strftime('%Y-%m-%d')
  s.description = readme_description
  s.email = %q{unxf@librelist.org}
  s.extra_rdoc_files = extra_rdoc_files(manifest)
  s.files = manifest
  s.rdoc_options = rdoc_options
  s.rubyforge_project = %q{rainbows}
  s.summary = summary
  s.test_files = test_files
  s.add_dependency('rack', '~> 1.1')
  s.add_development_dependency('wrongdoc', '~> 1.5')
  s.add_dependency('rpatricia', '~> 0.07')

  # s.license = %w(GPL) # disabled for compatibility with older RubyGems
end
