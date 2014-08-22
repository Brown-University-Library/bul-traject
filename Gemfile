    source "https://rubygems.org"

platforms :jruby do 
  gem 'traject', ">= 1.0.0.beta"
  gem 'marc'
  gem 'marc-marc4j'
  gem 'traject_umich_format'
  gem 'rspec'
end

if ENV['TRAJECT_ENV'] == 'devbox'
  gem 'byebug'
  gem "bulmarc", :path => "/work/bul_marc_utils"
else
  gem "bulmarc", :git => 'git@bitbucket.org:bul/bulmarc.git'
end

