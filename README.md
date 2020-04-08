# bul-traject
This project transforms Brown's MARC records into Solr documents using
[Traject](https://github.com/traject-project/traject) gem.


## Pre-requisites
Download and install Ruby:
```
brew install ruby-install
brew install chruby
ruby-install ruby 2.3.6
chruby 2.3.6
```


## Install the source code
```
cd /opt/local
git clone https://github.com/Brown-University-Library/bul-traject.git
mkdir -p .gem/ruby
gem install bundler --install-dir /opt/local/bul-traject/.gem/ruby

# Make our locally installed gems available to Ruby
export GEM_PATH=/opt/local/bul-traject/.gem/ruby:$GEM_PATH

# Make sure the bundler executable is in our path
export PATH=/opt/local/bul-traject/.gem/ruby/bin:$PATH

bundle config set path 'vendor/bundle'
bundle config set without 'development test'
bundle install
```


## Run
Run as
```
bundle exec traject -c config.rb -u http://localhost:8081/solr/blacklight-core /full/path/to/marcfile.mrc

curl http://localhost:8081/solr/blacklight-core/update?commit=true
```

For testing purposes you can run `traject` with the `--debug-mode` flag to
display the output to the console and not push the data to Solr.

```
bundle exec traject --debug-mode -c config.rb /full/path/to/marcfile.mrc
```


## Handling suppressed records
We use a separate process to delete records from Solr.
See [bibService project](https://github.com/Brown-University-Library/bibService) for more information on this.


## Scripts
Folder `./scripts` contains a few sample Bash scripts used to run Traject to
import a group of files, individual files, or for debug purposes.


## Solr 7
Folder `./solr7` contains the script to create our Solr core and some other files needed to configure our Solr core with the specific settings that we need.