module Datatable::Searching
  extend ActiveSupport::Concern

  included do
    class_attribute :searches
    self.searches = []
    extend ClassMethods
    include InstanceMethods
  end

  module ClassMethods
    def search_on(column_source, methods)
      Array(methods).each do |method|
        join column_source
        self.searches += [{column_source: column_source.to_s, method: method.to_s}]
      end
    end
  end

  module InstanceMethods
    attr_accessor :searches
  private
    def searches
      @searches ||= (self.columns.select(&:searchable).select{|c| c.column_source.present?}.map{|c| {column_source: c.column_source, method: c.method} } + self.class.searches).uniq
    end
    def search(terms)
      terms = terms.split if terms.is_a? String
      self.searches.map do |search|
        terms.map do |word|
          Squeel::Nodes::KeyPath.new(search[:column_source].split('.') << Squeel::Nodes::Stub.new(search[:method])) =~ "%#{word}%"
        end.compact.inject(&:|)
      end.compact.inject(&:|)
    end
  end

end