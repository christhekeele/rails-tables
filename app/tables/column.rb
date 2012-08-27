class Column

  attr_accessor :name, :column_name, :referring_column_name, :render_with, :sortable, :blank_value
  def initialize(name, *args)
    self.name = name

    attributes = args.pop || {}
    self.column_name = attributes.fetch(:column_name, name)
    self.referring_column_name = attributes.fetch(:referring_column_name, nil)
    self.render_with = attributes.fetch(:render_with, :default_render)
    self.sortable = attributes.fetch(:sortable, true)
    self.blank_value = attributes.fetch(:blank_value, '&ndash;')

    define_singleton_method :render do |view, object|
      if self.render_with.kind_of? Symbol
        content = self.send(self.render_with, view, object)
      else
        content = self.render_with.call(view, object)
      end
      content.present? ? content.to_s.html_safe : self.blank_value
    end
  end

  def default_render(view, object)
    property = object.send(self.column_name)
    property if not property.nil?
  end
  def self_referential_link(view, object)
    property = object.send(self.column_name)
    view.link_to property, object if not property.nil?
  end
  def related_link(view, object)
    property = object.send(self.column_name)
    view.link_to self.name, property if not property.nil?
  end
  def related_link_list(view, object)
    property = object.send(self.referring_column_name)
    property.collect { |related_object| self_referential_link(view, related_object) }.join(', ') if not property.nil?
  end
  def time(view, object)
    property = object.send(self.column_name)
    property.strftime("%I:%M%p") if not property.nil?
  end
  def date(view, object)
    property = object.send(self.column_name)
    property.strftime("%m/%d/%Y") if not property.nil?
  end
  def datetime(view, object)
    property = object.send(self.column_name)
    property.strftime("%m/%d/%Y at %I:%M%p") if not property.nil?
  end

end