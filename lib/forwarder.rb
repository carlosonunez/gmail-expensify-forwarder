require 'forwarder/receipts/search'
require 'forwarder/console'
require 'forwarder/aws'

GMAIL_USER_ID = 'default'
EMAIL_ADDR_TO_SEND_TO = ENV['EMAIL_ADDR_TO_SEND_TO'] || 'receipts@expensify.com'
MAX_EMAILS_MATCHED = ENV['MAX_RESULTS'] || 500
DEBUG_MODE = ENV['DEBUG_MODE']

module Forwarder
  def self.begin!
    if !ENV['USE_AWS'].nil? and ENV['USE_AWS'].downcase == 'true'
      Console.show_info_message 'AWS mode enabled!'
      Forwarder::AWS.load_environment_from_aws_ssm!
    end

    emails_found = Forwarder::Receipts::Search.find_receipts_within_gmail_since_last_run
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
    if !ENV['USE_AWS'].nil? and ENV['USE_AWS'].downcase == 'true'
      Forwarder::AWS.set_last_run_time_in_aws_ssm! time_finished_secs
    else
      Console.show_info_message "We've processed all of the messages " + \
        "that we could find. To re-run this script again from where we " + \
        "left off, set 'FORWARDER_LAST_FINISHED_TIME_SECS' to '#{time_finished_secs}'."
    end
  end
end
