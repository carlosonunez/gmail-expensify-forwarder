# This script is used during setup to generate tokens.
require 'forwarder'

raise "Define the credentials path" if ENV['CREDENTIALS_PATH'].nil?
raise "Define the tokens path" if ENV['TOKEN_PATH'].nil?

Forwarder::Gmail::Auth.sign_in!
