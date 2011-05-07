require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

LIBPATH = File.expand_path(File.dirname(__FILE__)) + File::SEPARATOR + 'lib'
require LIBPATH + File::SEPARATOR + 'q-ruby-driver'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "q-ruby-driver"
  gem.version = QRubyDriver::VERSION
  gem.homepage = "http://github.com/pdodds/q-ruby-driver"
  gem.license = "MIT"
  gem.summary = %Q{A pure Ruby implementation of the Q IPC protocol}
  gem.description = %Q{A Ruby interface to Q database from Kx Systems}
  gem.email = "philip.dodds at me dot com"
  gem.authors = ["Philip Dodds", "John Shields"]
  gem.files = FileList['lib/**/*.rb']
end

task :default => 'test:run'
task 'gem:release' => 'test:run'

# EOF
