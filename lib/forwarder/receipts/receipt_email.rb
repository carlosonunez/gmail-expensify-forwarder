require 'forwarder/gmail/send'

module Forwarder
  module Receipts
    class ReceiptEmail
      attr_reader :id, :raw

      def initialize(id, raw_message)
        @id = id
        @raw = raw_message
      end

      def send_with_gmail
        Forwarder::Gmail::Send.send_email_raw(@id, @raw)
      end
    end
  end
end
