module Forwarder
  module Receipts
    class ReceiptEmail
      attr_reader :id, :raw_message

      def initialize(id, raw_message)
        @id = id
        @raw_message = raw_message
      end
    end
  end
end
