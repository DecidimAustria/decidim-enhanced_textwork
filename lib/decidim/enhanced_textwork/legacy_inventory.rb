# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # Raw SQL intentionally avoids legacy models, default scopes and callbacks.
    # It also works when loaded into a 1.x application by bin/textwork-inventory.
    class LegacyInventory
      TABLE_PREFIX = "decidim_enhanced_textwork_"
      TYPE_PREFIX = "Decidim::EnhancedTextwork::"

      def initialize(connection)
        @connection = connection
      end

      def report
        tables = @connection.tables.sort
        legacy_tables = tables.grep(/\A#{TABLE_PREFIX}/)
        components = if tables.include?("decidim_components")
                       @connection.select_all("SELECT id, participatory_space_id, participatory_space_type FROM decidim_components " \
                                              "WHERE manifest_name = 'enhanced_textwork' ORDER BY id").to_a
                     else
                       []
                     end

        {
          format_version: 1,
          migration_supported: false,
          components:,
          tables: legacy_tables.index_with { |table| count(table) },
          references: reference_counts(tables - legacy_tables)
        }
      end

      private

      def count(table, column = nil)
        sql = "SELECT COUNT(*) FROM #{@connection.quote_table_name(table)}"
        sql += " WHERE #{@connection.quote_column_name(column)} LIKE #{@connection.quote("#{TYPE_PREFIX}%")}" if column
        @connection.select_value(sql).to_i
      end

      def reference_counts(tables)
        tables.each_with_object({}) do |table, result|
          @connection.columns(table).select { |column| column.name.end_with?("_type") && [:string, :text].include?(column.type) }.each do |column|
            total = count(table, column.name)
            result["#{table}.#{column.name}"] = total if total.positive?
          end
        end
      end
    end
  end
end
