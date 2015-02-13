source "https://rubygems.org"

gem 'marc'
gem 'rspec'
gem 'traject', :git => 'https://github.com/traject-project/traject.git', :tag => 'v2.0.0.rc.1'

#Check if we are using jruby and store.
is_jruby = RUBY_ENGINE == 'jruby'
if is_jruby
  gem 'traject-marc4j_reader'
else
  gem 'byebug'
end
