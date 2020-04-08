#!/bin/bash
#
# PRE-REQUISITES:
# 1. Ruby, chruby, and devtoolset-4 (g++)
# 2. Install bundler locally to this project:
#
# mkdir -p .gem/ruby
# gem install bundler --install-dir /opt/local/bul-traject/.gem/ruby
# mkdir .bundle/
# mv bundle_config_sample ./bundle/config

source /opt/local/chruby/share/chruby/chruby.sh
chruby 2.3.6
ruby -v

# Make our locally installed gems available to Ruby
export GEM_PATH=/opt/local/bul-traject/.gem/ruby:$GEM_PATH

# Make sure the bundler executable and the G++ excutable are in our PATH
export PATH=/opt/local/bul-traject/.gem/ruby/bin:/opt/rh/devtoolset-4/root/usr/bin:$PATH

# I am not sure we need this but setting them to keep things the same as in pblightcit
export CPP=/opt/rh/devtoolset-4/root/usr/bin/cpp
export CC=/opt/rh/devtoolset-4/root/usr/bin/gcc
export CXX=/opt/rh/devtoolset-4/root/usr/bin/c++

# echo $GEM_PATH
# echo $GEM_HOME
# echo $PATH

git pull
#bundle config path 'vendor/bundle'
#bundle config without 'development test'
bundle install
