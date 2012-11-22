class Column

  attr_accessor :model, :name, :method, :relation_chain, :render_with, :sortable, :searchable, :blank_value
  def initialize(model, name, *args)
    self.model = model
    self.name = name

    attributes = args.pop || {}
    self.method = attributes.fetch(:method, name)
    self.relation_chain = attributes.fetch(:relation_chain, [])
    self.relation_chain = [self.relation_chain] unless self.relation_chain.is_a? Array
    self.render_with = attributes.fetch(:render_with, :default_render)
    self.sortable = attributes.fetch(:sortable, true)
    self.searchable = attributes.fetch(:searchable, true)
    self.blank_value = attributes.fetch(:blank_value, '&ndash;')

    define_singleton_method :render do |view, object|
      self.relation_chain.each do |relation|
        object = object.try(:send, relation)
      end
      if self.render_with.kind_of? Symbol
        content = self.send(self.render_with, view, object)
      else
        content = self.render_with.call(view, object)
      end
      content.present? ? content.to_s.html_safe : self.blank_value
    end
  end

  def column_source
    model = self.model
    source_path = self.relation_chain.map do |relation|
      model = model.reflect_on_association(relation).klass
      model.table_name
    end << self.method
    source_path.join('.')
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
    view.link_to property, property if not property.nil?
  end
  def related_link_list(view, objects)
    objects.map{ |object| related_link(view, object) }.reject(&:nil?).join(', ') if not objects.nil?
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