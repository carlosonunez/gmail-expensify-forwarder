require 'aws-sdk-ssm'

module Forwarder
  class AWS
    def self.verify_environment
      [ 'AWS_ACCESS_KEY_ID', 'AWS_SECRET_ACCESS_KEY', 'AWS_REGION' ].each do |required_env_var|
        raise "AWS environment variable missing: #{required_env_var}" if ENV[required_env_var].nil?
      end
    end
      
    def self.set_last_run_time_in_aws_ssm!(time_to_put)
      verify_environment
      Console.show_debug_message "Setting the last run time to: #{time_to_put}"
      ssm_client = Aws::SSM::Client.new(region: ENV['AWS_REGION'])
      ssm_client.put_parameter({
        name: 'forwarder_last_finished_time_secs',
        description: 'The last time the Gmail to Expensify forwarder ran.',
        value: time_to_put,
        overwrite: true,
        type: 'String',
        tier: 'Standard'
      })
    end

    def self.load_environment_from_aws_ssm!
      verify_environment
      ssm_client = Aws::SSM::Client.new(region: ENV['AWS_REGION'])
      Console.show_debug_message "🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨"
      Console.show_debug_message "#{__method__.to_s} leaks sensitive info when " + \
        "DEBUG_MODE=true. Turn DEBUG_MODE off in Production to prevent yourself " + \
        "from getting pwn3d."
      Console.show_debug_message "🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨"
      [
        'FORWARDER_LAST_FINISHED_TIME_SECS',
        'CREDENTIALS',
        'TOKENS'
      ].each do |parameter|
        begin
          path_to_parameter = "/gmail-expensify-forwarder/#{parameter.downcase}"
          value = ssm_client.get_parameter({name: path_to_parameter}).parameter.value
          Console.show_debug_message "SSM Parameter: #{path_to_parameter} => #{value}"
          ENV[parameter] = value
        rescue Aws::SSM::Errors::ParameterNotFound
            raise "Couldn't load required parameter from SSM: '#{parameter.downcase}'"
        rescue Exception => e
          raise "An error occurred while trying to fetch '#{parameter.downcase}' from SSM: #{e}"
        end
      end
    end
  end
end
