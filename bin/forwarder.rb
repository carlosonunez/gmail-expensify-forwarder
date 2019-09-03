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
def begin
  Forwarder::begin!
end

Forwarder::begin!
