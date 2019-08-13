require 'google/apis/gmail_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'
require 'yaml'
require 'date'
require 'sqlite3'
require 'pry' if ENV['ENVIRONMENT'] == 'test'

USER_ID = 'default'
APPLICATION_NAME = ENV['APPLICATION_NAME'] || raise("Please set an APPLICATION_NAME.")
CREDENTIALS_PATH = ENV['CREDENTIALS_PATH'] || 'credentials.json'.freeze
TOKEN_PATH = ENV['TOKEN_PATH'] || 'token.yml'.freeze
FORWARDER_DB_PATH = ENV['FORWARDER_DB_PATH'] || '.forwarderdb'.freeze
OOB_URI = ENV['OOB_URI'] || 'urn:ietf:wg:oauth:2.0:oob'.freeze
LAST_AUTH_CODE = ENV['LAST_AUTHORIZATION_CODE']
MAX_EMAILS_MATCHED = ENV['MAX_RESULTS'] || 500
AUTH_SCOPES = [
  Google::Apis::GmailV1::AUTH_SCOPE,
  Google::Apis::GmailV1::AUTH_GMAIL_MODIFY,
  Google::Apis::GmailV1::AUTH_GMAIL_READONLY,
  Google::Apis::GmailV1::AUTH_GMAIL_SEND,
]


def init_forwarder_db
  forwarder_db = SQLite3::Database.new FORWARDER_DB_PATH
  forwarder_tables_found = \
    forwarder_db.execute <<-CHECK_FOR_FORWARDER_TABLE_SQL
      SELECT * FROM CHECK_FOR_FORWARDER_TABLE_SQLITE_MASTER
      WHERE type='table'
      AND name LIKE 'forwarder*'
    CHECK_FOR_FORWARDER_TABLE_SQL
  if forwarder_tables_found.empty? || forwarder_tables_found.length != 2
    begin
      forwarder_db.execute <<-CREATE_FORWARDER_TABLE_SQL
        CREATE TABLE forwarder (
          message_id TEXT
          status VARCHAR(16)
          PRIMARY KEY message_id
        );
        CREATE TABLE forwarder_metadata (
          last_run_time TEXT
        );
      CREATE_FORWARDER_TABLE_SQL
    rescue Exception => e
      raise "Unable to create forwarder table --- #{e}"
    end
  end
end

def get_last_run_time
  return ENV['LAST_RUN_TIME'] if !ENV['LAST_RUN_TIME'].nil?
  # TODO: Add S3 or DynamoDB code here.
end

# This will completely empty the token file; not good if working with
# multiple user IDs.
def clear_token_data_if_reauthorizing!
  if !ENV['REAUTHORIZE'].nil? && ENV['REAUTHORIZE'].downcase == 'true'
    File.open(TOKEN_PATH, 'w') {}
  end
end

def find_todays_matching_receipts(gmail_service)
  gmail_query = "label: Receipts " + \
                "after: #{Time.now.strftime('%Y/%m/%d')}"
  gmail_service.list_user_messages('me',
                                   max_results: MAX_EMAILS_MATCHED,
                                   q: gmail_query).messages
end

def initialize_gmail_service
  def authorize!
    clear_token_data_if_reauthorizing!
    client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
    token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
    authorizer = Google::Auth::UserAuthorizer.new client_id,
      AUTH_SCOPES,
      token_store
    credentials = authorizer.get_credentials USER_ID
    if credentials.nil?
      if ENV['REAUTHORIZE'] == 'true' || LAST_AUTH_CODE.nil?
        authorization_url = authorizer.get_authorization_url base_url: OOB_URI
        raise "Gmail OAuth token expired. Go to this url, then set the " \
          "LAST_AUTHORIZATION_CODE environment variable with the code " \
          "shown on the page: #{authorization_url}"
      else
        credentials = authorizer.get_and_store_credentials_from_code(
          user_id: USER_ID,
          code: LAST_AUTH_CODE,
          base_url: OOB_URI
        )
        if credentials.nil?
          raise "The Gmail OAuth authorization code was invalid. " + \
            "Check your LAST_AUTHORIZATION_CODE environment variable " + \
            "and try again."
        end
      end
    end
    credentials
  end

  service = Google::Apis::GmailV1::GmailService.new
  service.client_options.application_name = APPLICATION_NAME
  service.authorization = self.authorize!
  service
end

gmail_service = initialize_gmail_service
emails_found = find_todays_matching_receipts(gmail_service)
raise 'No receipts found.' if emails_found.nil?

emails_found.each do |email|
  if !email_already_sent?(email)
    begin
      send_email(email)
      mark_email_as_sent(email)
    rescue Exception => e
      puts "An error occurred while sending this email: #{e}\n"
      continue
    end
  end
end

puts "We found #{emails_found.length} emails."
