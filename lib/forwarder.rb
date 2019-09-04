require 'forwarder/receipts/search'
require 'forwarder/console'
require 'forwarder/aws'

module Forwarder
  def self.begin!
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
    emails_found.each do |email|
      begin
        email.send_with_gmail
      rescue Exception => e
        raise "Unable to send email: #{e}"
      end
    end

    time_finished_secs = Time.now.strftime('%s')

    if Forwarder::AWS::aws_enabled?
      Forwarder::AWS.set_last_run_time_in_aws_ssm! time_finished_secs
    else
      Console.show_info_message "We've processed all of the messages " + \
        "that we could find. To re-run this script again from where we " + \
        "left off, set 'FORWARDER_LAST_FINISHED_TIME_SECS' to '#{time_finished_secs}'."
    end
  end
end
