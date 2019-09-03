require 'aws-sdk-ssm'

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

    def self.verify_environment
      [ 'APP_AWS_ACCESS_KEY_ID', 'APP_AWS_SECRET_ACCESS_KEY', 'AWS_REGION' ].each do |required_env_var|
        raise "AWS environment variable missing: #{required_env_var}" if ENV[required_env_var].nil?
      end
    end
      
    def self.set_last_run_time_in_aws_ssm!(time_to_put)
      verify_environment
      Console.show_debug_message "Setting the last run time to: #{time_to_put}"
      @@ssm_client.put_parameter({
        name: 'forwarder_last_finished_time_secs',
        description: 'The last time the Gmail to Expensify forwarder ran.',
        value: time_to_put,
        overwrite: true,
        type: 'String',
      })
    end

    def self.get_parameter_from_ssm(parameter)
      verify_environment
      if !aws_enabled?
        Console.show_warning_message "AWS is disabled; can't fetch #{parameter}"
        return nil
      end
      Console.show_debug_message "🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨"
      Console.show_debug_message "#{__method__.to_s} leaks sensitive info when " + \
        "DEBUG_MODE=true. Turn DEBUG_MODE off in Production to prevent yourself " + \
        "from getting pwn3d."
      Console.show_debug_message "🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨"
      begin
        path_to_parameter = "/gmail-expensify-forwarder/#{parameter.downcase}"
        value = @@ssm_client.get_parameter({name: path_to_parameter}).parameter.value
        Console.show_debug_message "SSM Parameter: #{path_to_parameter} => #{value}"
        value
      rescue Aws::SSM::Errors::ParameterNotFound
        Console.show_error_message "Couldn't find parameter from SSM: '#{parameter.downcase}'"
        return nil
      rescue Exception => e
        Console.show_error_message "An error occurred while trying to fetch '#{parameter.downcase}' from SSM: #{e}"
        return nil
      end
    end
  end
end
