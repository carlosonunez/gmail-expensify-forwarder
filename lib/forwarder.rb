require 'forwarder/receipts/search'
require 'forwarder/console'
require 'forwarder/aws'

module Forwarder
  def self.process_receipts!
    email_sender = ENV['EMAIL_SENDER'] || Forwarder::AWS::get_parameter_from_ssm('email_sender')
    raise "Please define the address to send from." if email_sender.nil?
    expensify_address = ENV['EXPENSIFY_ADDRESS'] || \
      Forwarder::AWS::get_parameter_from_ssm('expensify_address') || \
      'receipts@expensify.com'
    emails_found = Forwarder::Receipts::Search.find_receipts_within_gmail_since_last_run(
      gmail_sender: email_sender,
      gmail_recipient: expensify_address
    )
    raise 'No receipts found.' if emails_found.nil?

    Console.show_info_message "We found #{emails_found.length} emails."
    message_index = 1
    emails_found.each do |email|
      begin
        Console.show_info_message "Sending message: #{message_index} of #{emails_found.length}"
        email.send_with_gmail
        message_index += 1
      rescue Exception => e
        raise "Unable to send email: #{e}"
      end
    end

    time_finished_secs = Time.now.strftime('%s')

    if Forwarder::AWS::aws_enabled?
      Forwarder::AWS.set_last_run_time_in_aws_ssm! time_finished_secs
    else
      Console.show_info_message "We've processed all of the messages that we could find!"
    end
  end
end
