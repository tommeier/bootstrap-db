module Bootstrap
  module Db
    module Log

      def log(output)
        STDERR.puts "[bootstrap-db] #{output}"
      end

    end
  end
end
