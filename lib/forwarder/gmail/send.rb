require 'forwarder/console'

module Forwarder
  module Gmail
    class Send
      def self.send_email_raw(id, raw_message_as_base64)
        begin
          Console.show_debug_message "Sending email with id '#{id}'"
          gmail_service = GmailService.new
          _ = gmail_service.service.send_user_message('me',
                                              upload_source: StringIO.new(raw_message_as_base64),
                                              content_type: 'message/rfc822')
        rescue Exception => e
          raise "Failed to send message: #{e}"
        end
      end
    end
  end
end
