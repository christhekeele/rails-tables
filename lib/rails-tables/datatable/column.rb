module RailsTables
  mattr_accessor :column_attributes
  self.column_attributes = [:name, :index, :table, :model, :method, :column_source, :render_with, :blank_value, :virtual, :sortable, :searchable]

  class ColumnBuilder
    attr_reader :column

    def self.define(column)
      binding.pry
      block = column.delete(:block)
      @builder = self.new(column)
      DslProxy.exec(@builder, &block) if block
      @builder.column
    end

    def initialize(column)
      @column = Column.from_hash(column)
    end

    RailsTables.column_attributes.each do |attr|
      define_method attr do |value|
        @column.send("#{attr}=".to_sym, value)
      end
    end

  end

  class Column < Struct.new(*RailsTables.column_attributes)
    def self.from_hash hash
      self[*hash.values_at(*self.members.map {|m| m.to_sym})]
    end

    def initialize(*args)
      super

      define_singleton_method :render do |view, object|
        if self.render_with.kind_of? Symbol
          content = self.send(self.render_with, view, follow_source(object))
        else
          content = self.render_with.call(view, follow_source(object))
        end
        content.present? ? content.to_s.html_safe : self.blank_value
      end
    end

    #   self.

    #   # self.method = attributes.fetch(:method, name).to_s
    #   # self.column_source = attributes.fetch(:column_source, '').to_s

    #   # virtual = (self.column_source.blank? and not self.model.column_names.include? self.method)
    #   # self.virtual = attributes.fetch(:virtual, virtual)
    #   # self.sortable = attributes.fetch(:sortable, !self.virtual)
    #   # self.searchable = attributes.fetch(:searchable, !self.virtual)

    #   # if virtual and not attributes.has_key?(:render_with)
    #   #   raise Exception,
    #   #     "Virtual columns are required to supply a render method (render_with: lambda): "\
    #   #     "Column: #{self.name}, Datatable: #{self.table_name}, Model: #{self.model.name}"
    #   # end

    #   # self.render_with = attributes.fetch(:render_with, :default_render)
    #   # self.blank_value = attributes.fetch(:blank_value, '&ndash;') 
    # end

  private

    def follow_source(object)
      related = object
      self.column_source.split('.').each do |relation|
        related = related.try(:send, relation)
      end
      related
    end

    def default_render(view, object)
      property = object.try(:send, self.method)
      property if not property.nil?
    end

    def self_referential_link(view, object)
      property = object.try(:send, self.method)
      view.link_to property, object if not property.nil?
    end
    def related_link(view, object)
      property = object.try(:send, self.method)
      view.link_to property, object if not property.nil?
    end
    def related_link_list(view, objects)
      objects.reject(&:blank?).map{ |object| related_link(view, object).strip }.join(', ') if not objects.nil?
    end

    def time(view, object)
      property = object.try(:send, self.method)
      property.strftime("%I:%M%p") if not property.nil?
    end
    def date(view, object)
      property = object.try(:send, self.method)
      property.strftime("%m/%d/%Y") if not property.nil?
    end
    def datetime(view, object)
      property = object.try(:send, self.method)
      property.strftime("%m/%d/%Y at %I:%M%p") if not property.nil?
    end

    def currency(view, object)
      property = object.try(:send, self.method)
      view.number_to_currency(property.to_f) if not property.nil?
    end
    def phone(view, object)
      property = object.try(:send, self.method)
      view.number_to_phone(property.to_f) if not property.nil?
    end

    def truncate(view, object)
      property = object.try(:send, self.method)
      view.truncate(property, 50) if not property.nil?
    end

  end
end