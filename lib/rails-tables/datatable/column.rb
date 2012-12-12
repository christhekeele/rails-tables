class RailsTables::Column

  attr_accessor :table_name, :model, :name, :order, :method, :column_source, :render_with, :blank_value, :virtual, :sortable, :searchable

  def initialize(table_name, model, name, order, *args)
    self.table_name = table_name
    self.model = model
    self.name = name
    self.order = order

    attributes = args.pop || {}
    self.method = attributes.fetch(:method, name).to_s
    self.column_source = attributes.fetch(:column_source, '').to_s

    virtual = (self.column_source.blank? and not self.model.column_names.include? self.method)
    self.virtual = attributes.fetch(:virtual, virtual)
    self.sortable = attributes.fetch(:sortable, !self.virtual)
    self.searchable = attributes.fetch(:searchable, !self.virtual)

    if virtual and not attributes.has_key?(:render_with)
      raise Exception,
        "Virtual columns are required to supply a render method (render_with: lambda): "\
        "Column: #{self.name}, Datatable: #{self.table_name}, Model: #{self.model.name}"
    end

    self.render_with = attributes.fetch(:render_with, :default_render)
    self.blank_value = attributes.fetch(:blank_value, '&ndash;')

    define_singleton_method :render do |view, object|
      if self.render_with.kind_of? Symbol
        content = self.send(self.render_with, view, follow_source(object))
      else
        content = self.render_with.call(view, object)
      end
      content.present? ? content.to_s.html_safe : self.blank_value
    end
  end

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

end