require 'forwarder/console'
require 'forwarder/email'
require 'google/apis/gmail_v1'

module Forwarder
  module Gmail
    class Search
      def find_emails_matching_query(query=nil)
        Forwarder::Gmail.ensure_initialized!
        show_debug_message "Searching for emails matching '#{query}'"
        gmail_service = Forwarder::Gmail.get_gmail_service
        gmail_service.list_user_messages('me',
                                         max_results: ENV['GMAIL_MAX_EMAILS_MATCHED'] || 500,
                                         q: query).messages.each do |message|
          begin
            # The /user/messages/send method in the Gmail API supports
            # two email representations: 'full' and 'raw'.
            # The 'raw' representation returns the email as a RFC 822 encoded
            # email message that can be used as-is to send to other receipients.
            # The 'full' representation is more flexible (returned as an object)
            # but requires more advanced parsing.
            # See also: https://developers.google.com/gmail/api/v1/reference/users/messages/send
            raw_message = gmail_service.get_user_message('me', message.id, format: 'raw').raw
            full_messages.push(ReceiptEmail.new(message.id, raw_message))
          rescue Exception => e
            raise "Error while attempting to get message #{message.id}: #{e}"
          end
        end
      end
    end
  end
end
