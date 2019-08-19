require 'google/apis/gmail_v1'
require 'forwarder/receipts/receipt_email'
require 'forwarder/console'
require 'forwarder/gmail'

module Forwarder
  module Gmail
    module Search
      def self.find_emails_matching_query(query = nil)
        Console.show_debug_message "Searching for emails matching '#{query}'"
        gmail_service = GmailService.new
        # TODO: I don't know if the `list_user_messages` method loads all
        #       emails found into memory, but if it doesn't,
        #       find a streambale way of doing this.
        messages_found = \
          gmail_service.service.list_user_messages('me',
                                                   max_results: ENV['GMAIL_MAX_EMAILS_MATCHED'] || 500,
                                                   q: query)
        Console.show_debug_message "~#{messages_found.result_size_estimate} messages found."
        return [] if messages_found.result_size_estimate == 0
        messages_to_return = []
        messages_found.messages.each do |message|
          begin
            # The /user/messages/send method in the Gmail API supports
            # two email representations: 'full' and 'raw'.
            # The 'raw' representation returns the email as a RFC 822 encoded
            # email message that can be used as-is to send to other receipients.
            # The 'full' representation is more flexible (returned as an object)
            # but requires more advanced parsing.
            # See also: https://developers.google.com/gmail/api/v1/reference/users/messages/send
            Console.show_debug_message "Fetching raw message for #{message.id}"
            raw_message = gmail_service.service.get_user_message('me', message.id, format: 'raw').raw
            messages_to_return.push(Receipts::ReceiptEmail.new(message.id, raw_message))
          rescue Exception => e
            raise "Error while attempting to get message #{message.id}: #{e}"
          end
        end
        messages_to_return
      end
    end
  end
end
