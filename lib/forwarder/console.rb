module Forwarder
  class Console
    def self.show_message(type, msg)
      type_color_kvp = {
        :debug => :cyan,
        :warn => :yellow,
        :error => :red,
        :info => :green
      }
      colorful_type = type.upcase.colorize(
        :color => type_color_kvp[type.to_sym],
        :mode => :bold
      )
      puts "#{colorful_type}: #{msg}"
    end

    def self.show_error_message(msg)
      show_message 'error', msg
    end

    def self.show_debug_message(msg)
      show_message 'debug', msg if !ENV['DEBUG_MODE'].nil? and ENV['DEBUG_MODE'].downcase == 'true'
    end

    def self.show_info_message(msg)
      show_message 'info', msg
    end

    def self.show_warning_message(msg)
      show_message 'warning', msg
    end
  end
end
