class Column

  attr_accessor :model, :name, :method, :column_source, :render_with, :sortable, :searchable, :blank_value
  def initialize(model, name, *args)
    self.model = model
    self.name = name

    attributes = args.pop || {}
    self.method = attributes.fetch(:method, name)
    self.column_source = attributes.fetch(:column_source, '').to_s
    self.render_with = attributes.fetch(:render_with, :default_render)
    self.sortable = attributes.fetch(:sortable, true)
    self.searchable = attributes.fetch(:searchable, true)
    self.blank_value = attributes.fetch(:blank_value, '&ndash;')

    define_singleton_method :render do |view, object|
      related = object
      self.column_source.split('.').each do |relation|
        related = related.try(:send, relation)
      end
      if self.render_with.kind_of? Symbol
        content = self.send(self.render_with, view, related)
      else
        content = self.render_with.call(view, object)
      end
      content.present? ? content.to_s.html_safe : self.blank_value
    end
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
    objects.reject(&:blank?).map{ |object| related_link(view, object).strip }.join(', ') if not objects.nil?
  end
  # def unique_related_link_list(view, objects, field)
  #   binding.pry if objects.length > 1
  #   related_link_list(view, objects.uniq{|o| o.send(field)} )
  # end
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