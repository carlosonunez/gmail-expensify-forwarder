#!/usr/bin/env ruby
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
