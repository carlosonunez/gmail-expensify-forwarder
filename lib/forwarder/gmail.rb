require 'forwarder/gmail/auth'
module Forwarder
  class Gmail
    @gmail_service = Forwarder::Gmail::Auth.sign_in! if @gmail_service.nil?

    def self.ensure_initialized?
      raise "Gmail service not ready" if @gmail_service.nil?
    end
  end
end
