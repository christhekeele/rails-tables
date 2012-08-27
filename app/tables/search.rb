class Search

  attr_accessor :name, :table, :column_name, :search_with
  def initialize(name, table, *args)
    self.name = name
    self.table = table

    attributes = args.pop || {}
    self.column_name = attributes.fetch(:column_name, name)
    self.search_with = attributes.fetch(:strategy, :default_strategy)

    
    define_singleton_method :search do |objects, terms|
      if self.search_with.kind_of? Symbol
        self.send(self.search_with, self.column_name, objects, terms)
      else
        self.search_with.call(self.column_name, objects, terms)
      end
    end
  end

  def default_strategy(field, objects, terms)
    self.starts_with_strategy(field, objects, terms)
  end
  def starts_with_strategy(field, objects, terms)
    terms.split.map{|s| s+="%"}.map do |term|
      Squeel::Nodes::Predicate.new(Squeel::Nodes::Stub.new(field), :matches, term)
    end.inject do |t, expr|
      t | expr
    end.tap do |block|
      return objects.where{block}
    end
  end
  def contains_strategy(field, objects, terms)
    terms.split.map{|s| s="%#{s}%"}.map do |term|
      Squeel::Nodes::Predicate.new(Squeel::Nodes::Stub.new(field), :matches, term)
    end.inject do |t, expr|
      t | expr
    end.tap do |block|
      return objects.where{block}
    end
  end
  # def self_referential_link(view, object)
  #   property = object.send(self.column_name)
  #   view.link_to property, object if not property.nil?
  # end
  # def related_link(view, object)
  #   property = object.send(self.column_name)
  #   view.link_to self.name, property if not property.nil?
  # end
  # def related_link_list(view, object)
  #   property = object.send(self.referring_column_name)
  #   property.collect { |related_object| self_referential_link(view, related_object) }.join(', ') if not property.nil?
  # end
  # def time(view, object)
  #   property = object.send(self.column_name)
  #   property.strftime("%I:%M%p") if not property.nil?
  # end
  # def date(view, object)
  #   property = object.send(self.column_name)
  #   property.strftime("%m/%d/%Y") if not property.nil?
  # end
  # def datetime(view, object)
  #   property = object.send(self.column_name)
  #   property.strftime("%m/%d/%Y at %I:%M%p") if not property.nil?
  # end

end