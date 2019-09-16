require 'forwarder/receipts/receipt_email'
require 'forwarder/gmail/search'
require 'forwarder/console'
require 'forwarder/aws'

module Forwarder
  module Receipts
    class Search
      # Changes the 'To' header in the email received to Expensify's
      # email address. This is done to work-around Gmail's forwarding
      # verification.
      def self.substitute_recipient_to_expensify_address(gmail_message,
                                                        recipient,
                                                        sender)
        raise "Message '#{gmail_message.id}' does not contain raw information." \
          if gmail_message.raw.nil?
        Console.show_debug_message "Modifying 'To' and 'From' headers for #{gmail_message.id}"
        reconstructed_message = gmail_message.raw.split("\n").map { |line|
          if /^To: / =~ line
            "To: #{recipient}"
          elsif /^From: / =~ line
            "From: #{sender}"
          elsif /^Content-Transfer-Encoding: quoted-printable/ =~ line
            ""
          else
            line
          end
        }.join("\n")
        ReceiptEmail.new(gmail_message.id, reconstructed_message)
      end

      # Gets any emails tagged with the 'Receipts' label since
      # this script last ran. Returns a list of raw messages (with 'To:'
      # headers modified) and their IDs.
      def self.find_receipts_within_gmail_since_last_run(gmail_recipient:, gmail_sender:)
        last_run_time_secs = Forwarder::AWS.get_parameter_from_ssm('FORWARDER_LAST_FINISHED_TIME_SECS')
        raise "Please set the time Forwarder finished last" if last_run_time_secs.nil?
        gmail_query = "label: Receipts " + \
                      "after: #{last_run_time_secs.to_i} " + \
                      "before: #{Time.now.strftime('%s')}"
        full_messages = []
        Gmail::Search.find_emails_matching_query(gmail_query).each do |message|
          begin
            # The /user/messages/send method in the Gmail API supports
            # two email representations: 'full' and 'raw'.
            # The 'raw' representation returns the email as a RFC 822 encoded
            # email message that can be used as-is to send to other receipients.
            # The 'full' representation is more flexible (returned as an object)
            # but requires more advanced parsing.
            # See also: https://developers.google.com/gmail/api/v1/reference/users/messages/send
            modified_message = substitute_recipient_to_expensify_address(
              message,
              gmail_recipient,
              gmail_sender
            )
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
