require 'forwarder/receipts/search'
require 'forwarder/console'

GMAIL_USER_ID = 'default'
EMAIL_ADDR_TO_SEND_TO = ENV['EMAIL_ADDR_TO_SEND_TO'] || 'receipts@expensify.com'
MAX_EMAILS_MATCHED = ENV['MAX_RESULTS'] || 500
DEBUG_MODE = ENV['DEBUG_MODE']

module Forwarder
  def self.begin!
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
  end
end
