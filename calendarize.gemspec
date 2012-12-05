$:.push File.expand_path('../lib', __FILE__)

require 'calendarize/version'

Gem::Specification.new do |s|
  s.name        = 'calendarize'
  s.version     = Calendarize::VERSION
  s.authors     = ['Jodi Giordano']
  s.email       = ['giordano.jodi@gmail.com']
  s.homepage    = 'http://www.semiweb.ca'
  s.summary     = 'A simple rails calendar helper.'
  s.description = 'This calendar helper was made for simple use cases of a calendar usage. No fancy stuff here.'

  s.files = Dir['{app,config,db,lib}/**/*'] + ['MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'rails', '>= 3.1.0'
  s.add_dependency 'turbolinks'

  s.add_development_dependency 'sqlite3'
end
