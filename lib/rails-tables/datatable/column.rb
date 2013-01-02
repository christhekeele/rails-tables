require "rails-tables/datatable/column/renderers"
module RailsTables
  mattr_accessor :column_attributes
  self.column_attributes = [:name, :index, :table, :model, :method_name, :column_source, :follow_source, :renderer, :blank_value, :virtual, :sortable, :searchable]

  class ColumnBuilder
    attr_reader :column
    def self.define(column)
      block = column.delete(:block)
      @builder = self.new(column)
      DslProxy.exec(@builder, &block) if block
      @builder.column
    end
    def initialize(column)
      @column = Column.from_hash(column)
    end
    RailsTables.column_attributes.reject{|c|c==:renderer}.each do |attr|
      define_method attr do |value|
        @column.send("#{attr}=".to_sym, value)
      end
    end
    def renderer(value=nil, &block)
      @column.renderer = block || value || nil
    end
  end

  Column = Struct.new(*RailsTables.column_attributes) do
    include RailsTables::Renderers
    # Arrange a hash into properly ordered array of args for this Struct
    def self.from_hash hash
      self[*hash.values_at(*self.members.map {|m| m.to_sym})]
    end
    # Set some defaults
    def initialize(*args)
      super
      self[:method_name]    = name.to_s                      if method_name.nil?
      self[:column_source]  = ''                             if column_source.nil?
      self[:renderer]       = :default_renderer              if renderer.nil?
      self[:follow_source]  = !self[:renderer].is_a?(Proc)   if follow_source.nil?
      self[:blank_value]    = '&mdash;'                      if blank_value.nil?
      self[:virtual]        = false                          if virtual.nil?
      self[:sortable]       = !virtual                       if sortable.nil?
      self[:searchable]     = !virtual                       if searchable.nil?

      define_singleton_method :render do |object|
        render_method = renderer.is_a?(Proc) ? renderer : method(renderer)
        object = follow_source_on(object) if follow_source
        content = self.instance_exec object, &render_method
        content.present? ? content.to_s.html_safe : blank_value
      end
    end

  private

    def follow_source_on(object)
      related = object
      column_source.to_s.split('.').each do |relation|
        related = related.try(:send, relation)
      end
      related
    end

    def default_renderer(object)
      object.send(method_name) if object.respond_to? method_name
    end

    def respond_to?(sym)
      if table.view.respond_to? sym
        true
      elsif table.locals.has_key? sym
        true
      else
        super
      end
    end

    def method_missing(sym, *args)
      if table.view.respond_to? sym
        table.view.send(sym, *args)
      elsif table.locals.has_key? sym
        table.locals[sym]
      else
        super
      end
    end

  end
end