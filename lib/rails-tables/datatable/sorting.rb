module RailsTables::Sorting
  extend ActiveSupport::Concern

  included do
    class_attribute :initial_orderings
    extend ClassMethods
  end

  module ClassMethods
    # Gotta set these to fight against datatables' default ordering on first column
    def initial_ordering(orderings)
      self.set_initial_orderings orderings
    end
    def set_initial_orderings(orderings)
      self.initial_orderings = {} if self.initial_orderings.nil?
      self.initial_orderings.merge! orderings
    end

  end

  # InstanceMethods
private
  # Check if table is sortable
  def sortable
    self.columns.map{ |column| column.sortable }[params[:iSortCol_0].to_i] unless params[:bUseDefaultSort] == 'true'
  end
  # Find column to search by and create a Squeel Order
  def sort
    column = self.columns[params[:iSortCol_0].to_i]
    if column.sortable
      direction = params[:sSortDir_0] == "asc" ? 1 : -1
      Squeel::Nodes::KeyPath.new(column.column_source.split('.') << Squeel::Nodes::Order.new(Squeel::Nodes::Stub.new(column.method), direction))
    end
  end

end