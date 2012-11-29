module Datatable::Sorting
  extend ActiveSupport::Concern

  included do
    class_attribute :initial_orderings
    extend ClassMethods
    include InstanceMethods
  end

  module ClassMethods

    def initial_ordering(orderings)
      self.set_initial_orderings orderings
    end
    def set_initial_orderings(orderings)
      self.initial_orderings = {} if self.initial_orderings.nil?
      self.initial_orderings.merge! orderings
    end

  end

  module InstanceMethods
  private
    def sortable
      self.columns.map{ |column| column.sortable }[params[:iSortCol_0].to_i] unless params[:bUseDefaultSort] == 'true'
    end
    def sort
      column = self.columns[params[:iSortCol_0].to_i]
      if column.sortable
        binding.pry
        direction = params[:sSortDir_0] == "asc" ? 1 : -1
        Squeel::Nodes::KeyPath.new(column.column_source.split('.') << Squeel::Nodes::Order.new(column.method, direction))
      end
    end
  end

end