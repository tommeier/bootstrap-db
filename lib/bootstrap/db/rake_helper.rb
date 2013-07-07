module Bootstrap
  module Db
    module RakeHelper

      def log(output)
        STDERR.puts "[bootstrap-db] #{output}"
      end

      def display_and_execute(command)
        log(command) if ENV['VERBOSE'] == 'true'
        execute_command(command)
      end

      def execute_command(command)
        output = `#{command} 2>&1`
        raise "Error : #{output}" unless $?.success?
        output
      end
    end
  end
end
