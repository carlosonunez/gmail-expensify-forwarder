require 'base64'
require 'colorize'
require 'date'
require 'fileutils'
require 'yaml'
require 'pry' if ENV['ENVIRONMENT'] == 'test'
require 'forwarder'

Forwarder::begin!
