require "shikashi"
require 'active_support'
module Bootstrap
  module Db
    class Rebase
      include Shikashi

      #TODO: track "*objects" and no need for value then, can just object.send(field_name)
      def self.freeze!(table_name, field_name, value, *ids)
        @_frozen_attributes ||= {}
        @_frozen_attributes[table_name] ||= {}
        @_frozen_attributes[table_name][field_name] ||= {}

        # { table_name => {
        #     field_name => {
        #       ids => [1,3,4,5],
        #       value => 'Something'
        #     }
        # }
        frozen_field_ids = @_frozen_attributes[table_name][field_name][:ids] ||= []
        frozen_field_ids += ids.compact.flatten

        @_frozen_attributes[table_name][field_name][:value] = value.to_s
        @_frozen_attributes[table_name][field_name][:ids]   = frozen_field_ids.uniq
      end

      def self.frozen
        @_frozen_attributes
      end

      # TODO: DRY this up if spike works out
      def self.post_process!(table_name, field_name, value, *ids)
        @_post_process ||= {}
        @_post_process[table_name] ||= {}
        @_post_process[table_name][field_name] ||= {}

        # { table_name => {
        #     field_name => {
        #       ids => [1,3,4,5],
        #       value => 'Something'
        #     }
        # }
        post_process_ids = @_post_process[table_name][field_name][:ids] ||= []
        post_process_ids += ids.compact.flatten

        @_post_process[table_name][field_name][:value] = value.to_s
        @_post_process[table_name][field_name][:ids]   = post_process_ids.uniq
      end

      def self.post_processing
        @_post_process
      end
    end
  end
end
