source "https://rubygems.org"

gem 'marc'
gem 'rspec'

#Check if we are using jruby and store.
is_jruby = RUBY_ENGINE == 'jruby'
if is_jruby
  gem 'traject', ">= 1.0.0.beta"
  gem 'marc-marc4j'
else
  gem 'byebug'
  gem 'traject', '>=2.0.pre', :git => 'https://github.com/traject-project/traject.git', :branch => 'dev-2.0'
end
