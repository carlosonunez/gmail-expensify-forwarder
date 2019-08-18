require 'forwarder/receipts/receipt_email'
require 'forwarder/gmail/search'

module Forwarder
  module Receipts
    class Search
      # Changes the 'To' header in the email received to Expensify's
      # email address. This is done to work-around Gmail's forwarding
      # verification.
      def self.substitute_recipient_to_expensify_address(gmail_message)
        raise "Message '#{message.id}' does not contain raw information." \
          if gmail_message.raw.nil?
        show_debug_message "Modifying message #{gmail_message.id}"
        reconstructed_message = message.raw.split("\n").map { |line|
          /To: / =~ line ? "To: receipts@expensify.com\r" : line
        }
        ReceiptEmail.new(gmail_message.id, reconstructed_message)
      end

      # Gets any emails tagged with the 'Receipts' label since
      # this script last ran. Returns a list of raw messages (with 'To:'
      # headers modified) and their IDs.
      def self.find_receipts_since_last_run
        [ 'LAST_RUN_START', 'LAST_RUN_END' ].each do |required_var|
          raise "Please define #{required_var}" if ENV[required_var].nil?
        end
        gmail_query = "label: Receipts " + \
                      "before: #{ENV['LAST_RUN_END'].to_i.strftime('%s')} " + \
                      "after: #{ENV['LAST_RUN_START'].to_i.strftime('%s')}"
        full_messages = []
        Forwarder::Gmail::Search.find_emails_matching_query(gmail_query).messages.each do |message|
          begin
            # The /user/messages/send method in the Gmail API supports
            # two email representations: 'full' and 'raw'.
            # The 'raw' representation returns the email as a RFC 822 encoded
            # email message that can be used as-is to send to other receipients.
            # The 'full' representation is more flexible (returned as an object)
            # but requires more advanced parsing.
            # See also: https://developers.google.com/gmail/api/v1/reference/users/messages/send
            modified_message = substitute_recipient_to_expensify_address message
            full_messages.push(modified_message)
          rescue Exception => e
            raise "Error while attempting to get message #{message.id}: #{e}"
          end
        end
        full_messages
      end
    end
  end
end
