require 'aws-sdk-ssm'
require 'digest'

module Forwarder
  class AWS
    def self.aws_enabled?
      !ENV['USE_AWS'].nil? and ENV['USE_AWS'].downcase == 'true'
    end

    if aws_enabled?
      @@ssm_client = Aws::SSM::Client.new({
        region: ENV['AWS_REGION'],
        access_key_id: ENV['APP_AWS_ACCESS_KEY_ID'],
        secret_access_key: ENV['APP_AWS_SECRET_ACCESS_KEY']
      })
    end

    def self.get_hashed_email_address
      raise "Google account not provided" if ENV['GOOGLE_ACCOUNT_EMAIL'].nil?

      Console.show_debug_message "Hashing: #{ENV['GOOGLE_ACCOUNT_EMAIL']}"
      Digest::MD5.hexdigest ENV['GOOGLE_ACCOUNT_EMAIL']
    end

    def self.verify_environment
      [ 'APP_AWS_ACCESS_KEY_ID', 
        'APP_AWS_SECRET_ACCESS_KEY',
        'AWS_REGION' ].each do |required_env_var|
        raise "AWS environment variable missing: #{required_env_var}" if ENV[required_env_var].nil?
      end
    end
      
    def self.set_last_run_time_in_aws_ssm!(time_to_put)
      if !ENV['FORWARDER_LAST_FINISHED_TIME_SECS'].nil?
        Console.show_warning_message "Last time to use set in environment; skipping."
      else
        verify_environment
        ga_hash = self.get_hashed_email_address
        Console.show_debug_message "Setting the last run time to: #{time_to_put}"
        @@ssm_client.put_parameter({
          name: "/gmail-expensify-forwarder/#{ga_hash}/forwarder_last_finished_time_secs",
          description: 'The last time the Gmail to Expensify forwarder ran.',
          value: time_to_put,
          overwrite: true,
          type: 'String',
        })
      end
    end

    def self.get_parameter_from_ssm(parameter)
      verify_environment
      Console.show_debug_message "🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨"
      Console.show_debug_message "#{__method__.to_s} leaks sensitive info when " + \
        "DEBUG_MODE=true. Turn DEBUG_MODE off in Production to prevent yourself " + \
        "from getting pwn3d."
      Console.show_debug_message "🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨"
      begin
        if !ENV[parameter.upcase].nil?
          Console.show_warning_message "#{parameter} was found in local environment; skipping."
          return ENV[parameter.upcase]
        end
        if !aws_enabled?
          Console.show_debug_message "AWS is disabled; can't fetch #{parameter}"
          return nil
        end
        ga_hash = self.get_hashed_email_address
        path_to_parameter = "/gmail-expensify-forwarder/#{ga_hash}/#{parameter.downcase}"
        Console.show_debug_message "SSM Parameter: #{path_to_parameter}"
        value = @@ssm_client.get_parameter({name: path_to_parameter}).parameter.value
        Console.show_debug_message "SSM Parameter: #{path_to_parameter} => #{value}"
        value
      rescue Aws::SSM::Errors::ParameterNotFound
        Console.show_warning_message "Couldn't find parameter from SSM: '#{parameter.downcase}'"
        return nil
      rescue Exception => e
        Console.show_error_message "An error occurred while trying to fetch '#{parameter.downcase}' from SSM: #{e}"
        return nil
      end
    end
  end
end
