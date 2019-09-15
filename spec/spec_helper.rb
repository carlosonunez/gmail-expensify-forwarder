require 'rspec'
require 'rspec-expectations'
Dir.glob['../lib/forwarder/**/*.rb'].each do |file|
  require_relative file
end

def read_test_file(file)
  File.read("spec/files/#{file}")
end
