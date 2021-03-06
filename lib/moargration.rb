module Moargration
  class Exception < StandardError; end

  extend self

  def init
    @@columns_to_ignore = {}
    return unless ignore = ENV["MOARGRATION_IGNORE"]
    self.columns_to_ignore = parse(ignore)
    hack_active_record!
  end

  def columns_to_ignore=(columns)
    @@columns_to_ignore = columns
  end

  def columns_to_ignore
    @@columns_to_ignore
  end

  def ignoring?(table, column)
    ignored_columns = columns_to_ignore[table.to_s] || []
    ignored_columns.include?(column.to_s)
  end

  def parse(text)
    text.strip.split(" ").inject({}) do |parsed, definition|
      table, fields = definition.split(":", 2)
      parsed[table] = fields.split(",") if fields
      parsed
    end
  end

  def hack_active_record!
    ActiveRecord::Base.class_eval do
      class << self
        alias :columns_without_moargration :columns
        def columns
          unless defined?(@cached_moargration_columns) && @cached_moargration_columns
            @cached_moargration_columns = columns_without_moargration.reject do |column|
              (Moargration.columns_to_ignore[table_name] || []).include?(column.name)
            end
          end
          @cached_moargration_columns
        end
      end
    end
  end
end
