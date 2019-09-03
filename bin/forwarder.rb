#!/usr/bin/env ruby
$LOAD_PATH.unshift('./lib')
if Dir.exist? './vendor'
  $LOAD_PATH.unshift('./vendor/bundle/gems/**/lib')
end

require 'base64'
require 'colorize'
require 'date'
require 'fileutils'
require 'yaml'
require 'pry' if ENV['ENVIRONMENT'] == 'test'
require 'forwarder'

# For use with AWS Lambda and other serverless services
# For some reason, Lambda provides an argument to this function.
# Not sure what to do with it yet, so I'm discarding it.
def begin(_)
  Forwarder::begin!
end

Forwarder::begin!
