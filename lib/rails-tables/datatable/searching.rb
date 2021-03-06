module RailsTables::Searching
  extend ActiveSupport::Concern

  included do
    class_attribute :searches
    self.searches = []
    extend ClassMethods
  end

  module ClassMethods
    # Allow user defined fields to sort on in addition to introspected fields
    def search_on(column_source, methods)
      Array(methods).each do |method_name|
        join column_source
        self.searches += [{column_source: column_source.to_s, method_name: method_name.to_s}]
      end
    end
  end

  # InstanceMethods
  attr_accessor :searches

private

  def searchable
    params[:sSearch].present?
  end
  # Introspect available searches as well as user defined ones
  def searchables
    searches = self.columns.
      select(&:searchable).
      map{ |c| {column_source: c.column_source, method_name: c.method_name} }
    searches += self.class.searches
    @searches ||= searches.uniq
  end
  # Build Squeel Stubs for search
  def search(terms)
    terms = terms.split if terms.is_a? String
    searchables.map do |search|
      terms.map do |word|
        Squeel::Nodes::KeyPath.new(search[:column_source].to_s.split('.') << Squeel::Nodes::Stub.new(search[:method_name].to_s)) =~ "%#{word}%"
      end.compact.inject(&:|)
    end.compact.inject(&:|)
  end

end