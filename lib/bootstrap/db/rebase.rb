module Bootstrap
  module Db
    class Rebase

      def self.freeze!(table_name, field_name, *ids)
        @_frozen_attributes ||= {}
        @_frozen_attributes[table_name] ||= {}

        frozen_field_ids = @_frozen_attributes[table_name][field_name] ||= []
        frozen_field_ids += ids.compact.flatten
        @_frozen_attributes[table_name][field_name] = frozen_field_ids.uniq
      end

      def self.frozen
        @_frozen_attributes
      end
    end
  end
end
