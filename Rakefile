
begin
  require 'bones'
rescue LoadError
  abort '### Please install the "bones" gem ###'
end

ensure_in_path 'lib'
require 'q-ruby-driver'

task :default => 'test:run'
task 'gem:release' => 'test:run'

Bones {
  name  'q-ruby-driver'
  authors  'Philip Dodds'
  email  'philip.dodds at me dot com'
  url  'http://www.github.com/pdodds/q-ruby-driver'
  version  QRubyDriver::VERSION
}

# EOF
