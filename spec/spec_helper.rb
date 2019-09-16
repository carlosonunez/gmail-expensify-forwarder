require 'rspec'
require 'ostruct'
require 'forwarder'

def read_test_file(file)
  File.read("spec/files/#{file}").strip
end
