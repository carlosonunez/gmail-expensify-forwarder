require 'forwarder/gmail'
require 'forwarder/receipts/search'

GMAIL_USER_ID = 'default'
EMAIL_ADDR_TO_SEND_TO = ENV['EMAIL_ADDR_TO_SEND_TO'] || 'receipts@expensify.com'
GMAIL_APPLICATION_NAME = ENV['GMAIL_APPLICATION_NAME'] || raise("Please set an GMAIL_APPLICATION_NAME.")
GMAIL_MESSAGES_TIME_OFFSET_SECONDS = ENV['GMAIL_MESSAGES_TIME_OFFSET_SECONDS'].to_i || 60
CREDENTIALS_PATH = ENV['CREDENTIALS_PATH'] || 'credentials.json'.freeze
TOKEN_PATH = ENV['TOKEN_PATH'] || 'token.yml'.freeze
GMAIL_OAUTH_OOB_URI = ENV['GMAIL_OAUTH_OOB_URI'] || 'urn:ietf:wg:oauth:2.0:oob'.freeze
LAST_AUTH_CODE = ENV['LAST_AUTHORIZATION_CODE']
MAX_EMAILS_MATCHED = ENV['MAX_RESULTS'] || 500
DEBUG_MODE = ENV['DEBUG_MODE']
GMAIL_AUTH_SCOPES = [
  Google::Apis::GmailV1::AUTH_SCOPE,
  Google::Apis::GmailV1::AUTH_GMAIL_MODIFY,
  Google::Apis::GmailV1::AUTH_GMAIL_READONLY,
  Google::Apis::GmailV1::AUTH_GMAIL_SEND,
]

def begin!
  emails_found = Forwarder::Receipts::Search.find_receipts_since_last_run
  raise 'No receipts found.' if emails_found.nil?

  show_info_message "We found #{emails_found.length} emails."
  emails_found.each do |email|
    begin
      Forwarder::Gmail::Send.send_email_from_raw_message(gmail_service,
                                                         raw_message_as_base64: email_to_send)
    rescue Exception => e
      raise "Unable to send email: #{e}"
    end
  end
end
