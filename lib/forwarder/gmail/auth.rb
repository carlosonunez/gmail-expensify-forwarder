require 'google/apis/gmail_v1'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'forwarder/aws'

module Forwarder
  module Gmail
    module Auth
      @gmail_environment = {
        :credentials_path => ENV['CREDENTIALS_PATH'] || '/tmp/credentials.json',
        :credentials => ENV['CREDENTIALS'] || Forwarder::AWS::get_parameter_from_ssm('CREDENTIALS'),
        :token_path => ENV['TOKEN_PATH'] || '/tmp/tokens.yml',
        :tokens => ENV['TOKENS'] || Forwarder::AWS::get_parameter_from_ssm('TOKENS'),
        :reauthorize => ENV['REAUTHORIZE'].to_s.downcase == 'true',
        :last_auth_code => ENV['LAST_AUTH_CODE'],
        :wait_for_auth_code => ENV['WAIT_FOR_AUTH_CODE'].to_s.downcase == 'true',
        :auth_scopes => ['SCOPE','GMAIL_READONLY','GMAIL_SEND'].map {|scope_name|
          eval "Google::Apis::GmailV1::AUTH_#{scope_name}"
        },
        :user_id => ENV['GMAIL_USER_ID'] || 'default',
        :oauth_oob_url => ENV['GMAIL_OAUTH_OOB_URI'] || 'urn:ietf:wg:oauth:2.0:oob'.freeze,
        :app_name => ENV['GMAIL_APPLICATION_NAME'] || \
          Forwarder::AWS::get_parameter_from_ssm('GMAIL_APPLICATION_NAME')
      }

      def self.validate_environment!
        [ :credentials_path, :user_id, :app_name, :token_path ].each do |required_env_var|
          raise "Please define #{required_env_var.to_s.upcase}" \
            if @gmail_environment[required_env_var].nil?
        end
      end

      def self.clear_token_data_if_reauthorizing!
        if @gmail_environment[:reauthorize]
          File.open(@gmail_environment[:token_path], 'w') {}
        end
      end

      def self.attempt_auth_with_reauth_code(gmail_authorizer)
        if @gmail_environment[:reauthorize] || @gmail_environment[:last_auth_code].nil?
          authorization_url = gmail_authorizer.get_authorization_url(
            base_url: @gmail_environment[:oauth_oob_url]
          )
          if @gmail_environment[:wait_for_auth_code]
            puts "Gmail Oauth token expired. Go to #{authorization_url}, then " \
              "paste the code provided here: "
            auth_code = gets
            if !auth_code.nil?
              @gmail_environment[:last_auth_code] = auth_code
              self.attempt_auth_with_reauth_code(gmail_authorizer)
            else
              raise "Invalid auth code provided."
            end
          else
            raise "Gmail OAuth token expired. Go to this url, then set the " \
              "LAST_AUTH_CODE environment variable with the code " \
              "shown on the page: #{authorization_url}"
          end
        else
          begin
            gmail_authorizer.get_and_store_credentials_from_code(
              user_id: @gmail_environment[:user_id],
              code: @gmail_environment[:last_auth_code],
              base_url: @gmail_environment[:oauth_oob_url]
            )
          rescue Exception
            raise "The Gmail OAuth authorization code was invalid. " + \
              "Check your LAST_AUTH_CODE environment variable " + \
              "and try again."
          end
        end
      end

      def self.authorize!
        clear_token_data_if_reauthorizing!
        if !@gmail_environment[:credentials].nil?
          credentials_path_to_use = @gmail_environment[:credentials_path]
          File.open(credentials_path_to_use, 'w') { |file|
            file.write(@gmail_environment[:credentials])
          }
        else
          raise "Creds file not found at #{@gmail_environment[:credentials_path]}" \
            if !File.exist? @gmail_environment[:credentials_path]
          credentials_path_to_use = @gmail_environment[:credentials_path]
        end
        client_id = Google::Auth::ClientId.from_file credentials_path_to_use
        if !@gmail_environment[:tokens].nil?
          token_path_to_use = @gmail_environment[:token_path]
          File.open(token_path_to_use, 'w') { |file|
            file.write(@gmail_environment[:tokens])
          }
        else
          token_path_to_use = @gmail_environment[:token_path]
        end
        token_store = Google::Auth::Stores::FileTokenStore.new(
          file: token_path_to_use
        )
        authorizer = Google::Auth::UserAuthorizer.new client_id,
          @gmail_environment[:auth_scopes],
          token_store
        credentials = authorizer.get_credentials @gmail_environment[:user_id]
        if credentials.nil?
          attempt_auth_with_reauth_code authorizer
        end
        credentials
      end

      def self.sign_in!
        validate_environment!
        service = Google::Apis::GmailV1::GmailService.new
        service.client_options.application_name = @gmail_environment[:gmail_application_name]
        service.authorization = authorize!
        service
      end
    end
  end
end

