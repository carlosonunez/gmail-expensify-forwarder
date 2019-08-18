module Forwarder
  module Gmail
    class Send
      def send_email_from_raw_message(raw_message_as_base64)
        Forwarder::Gmail.ensure_initialized!
        begin
          gmail_service = Forwarder::Gmail.get_gmail_service
          _ = gmail_service.send_user_message('me',
                                              upload_source: StringIO.new(raw_message_as_base64),
                                              content_type: 'message/rfc822')
        rescue Exception => e
          raise "Failed to send message '#{message.id}': #{e}"
        end
      end
    end
  end
end
