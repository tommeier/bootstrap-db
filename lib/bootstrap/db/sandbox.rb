require "shikashi"
require "active_support"

module Bootstrap
  module Db
    #Sandbox to only allow time/date calculations to be performed
    class Sandbox
      include Shikashi

      SANDBOX   = Shikashi::Sandbox.new
      TIMELORD  = Shikashi::Privileges.new

      BASE_CLASSES = [
        Time, Date, DateTime, Numeric, Fixnum, Integer, Float
      ]

      #::DateAndTime::Calculations
      RAILS_CLASSES = [
        ::ActiveSupport::Duration, ::ActiveSupport::TimeZone, ::ActiveSupport::TimeWithZone
      ]
      ALLOWED_CLASSES = BASE_CLASSES + RAILS_CLASSES

      TIMELORD.allow_const_read(*ALLOWED_CLASSES)

      ALLOWED_CLASSES.each do |klass|
        TIMELORD.object(klass).allow_all
        TIMELORD.methods_of(klass).allow_all
      end

      # Run any
      def self.run(eval_command)
        SANDBOX.run(TIMELORD, eval_command)
      end
    end
  end
end
