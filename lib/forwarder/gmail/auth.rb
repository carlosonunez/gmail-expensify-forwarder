require 'google/apis/gmail_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'

module Forwarder
  module Gmail
    class Auth
      def clear_token_data_if_reauthorizing!
        if !ENV['REAUTHORIZE'].nil? && ENV['REAUTHORIZE'].downcase == 'true'
          File.open(TOKEN_PATH, 'w') {}
        end
      end

      def initialize_gmail_service
        def validate! 
          ['CREDENTIALS_PATH', 'TOKEN_PATH'].each do |required_path|
            raise "Please define a #{required_path}" if ENV[required_path].nil?
            raise "Path not found: #{required_path}" if !File.exist(ENV[required_path])
          end

          [
            'GMAIL_AUTH_SCOPES',
            'GMAIL_USER_ID',
            'GMAIL_OAUTH_OOB_URI',
            'GMAIL_APPLICATION_NAME'
          ].each do |required_env_var|
            raise "Please define #{required_env_var}" if ENV[required_env_var].nil?
          end
        end

        def create_scopes_from_env
          scopes = [Google::Apis::GmailV1::AUTH_SCOPE]
          ENV['GMAIL_AUTH_SCOPES'].split(',').each do |scope|
            scopes.push(eval("Google::Apis::GmailV1::AUTH_GMAIL_#{scope.upcase}"))
          end
        end

        def attempt_auth_with_reauth_code
          if ENV['REAUTHORIZE'] == 'true' || ENV['LAST_AUTH_CODE'].nil?
            authorization_url = authorizer.get_authorization_url(
              base_url: ENV['GMAIL_OAUTH_OOB_URI']
            )
            raise "Gmail OAuth token expired. Go to this url, then set the " \
              "LAST_AUTHORIZATION_CODE environment variable with the code " \
              "shown on the page: #{authorization_url}"
          else
            credentials = authorizer.get_and_store_credentials_from_code(
              user_id: ENV['GMAIL_USER_ID,'],
              code: ENV['LAST_AUTH_CODE,'],
              base_url: ENV['GMAIL_OAUTH_OOB_URI']
            )
            if credentials.nil?
              raise "The Gmail OAuth authorization code was invalid. " + \
                "Check your LAST_AUTH_CODE environment variable " + \
                "and try again."
            end
          end
        end

        def authorize!
          validate!
          gmail_auth_scopes = create_scopes_from_env
          clear_token_data_if_reauthorizing!
          client_id = Google::Auth::ClientId.from_file ENV['CREDENTIALS_PATH']
          token_store = Google::Auth::Stores::FileTokenStore.new(
            file: ENV['TOKEN_PATH']
          )
          authorizer = Google::Auth::UserAuthorizer.new client_id,
            gmail_auth_scopes,
            token_store
          credentials = authorizer.get_credentials ENV['GMAIL_USER_ID']
          if credentials.nil?
            attempt_auth_with_reauth_code
          end
          credentials
        end

        def self.sign_in!
          service = Google::Apis::GmailV1::GmailService.new
          service.client_options.application_name = ENV['GMAIL_APPLICATION_NAME']
          service.authorization = self.authorize!
          service
        end
      end
    end
  end
end

