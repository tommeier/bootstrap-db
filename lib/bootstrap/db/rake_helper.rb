module Bootstrap
  module Db
    module RakeHelper

      def log(output)
        STDERR.puts output
      end

      def display_and_execute(command, display)
        STDERR.puts command if display
        execute_command(command)
      end

      def execute_command(command)
        `#{command}`
      end

      def run_rake(task)
        Rake::Task[task].reenable
        Rake::Task[task].invoke
      end
    end
  end
end
