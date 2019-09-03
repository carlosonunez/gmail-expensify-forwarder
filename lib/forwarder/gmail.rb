require 'forwarder/gmail/auth'
module Forwarder
  module Gmail
    class GmailService
      attr_reader :service

      def self.ensure_initialized?
        raise "Gmail service not ready" if @service.nil?
      end

      def initialize
        return @service if !@service.nil?

        begin
          @service = Gmail::Auth.sign_in!
        rescue Exception
          raise "Unable to sign into Gmail; see errors above for more information."
        end
      end
    end
  end
end
