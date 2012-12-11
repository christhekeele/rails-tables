module RailsTables::Sorting
  extend ActiveSupport::Concern

  included do
    class_attribute :initial_ordering
    extend ClassMethods
  end

  module ClassMethods
    # Gotta set these to fight against datatables' default ordering on first column
    # def initial_ordering(orderings)
    #   self.set_initial_orderings orderings
    # end
    # def set_initial_orderings(orderings)
    #   self.initial_orderings = {} if self.initial_orderings.nil?
    #   self.initial_orderings.merge! orderings
    # end

  end

  # InstanceMethods
private
  # Check if table is sortable
  def sortable
    if params[:bUseDefaultSort] == 'true'
      true
    else
      self.columns.map(&:sortable)[params[:iSortCol_0].to_i]
    end
  end
  # Find column to search by and create a Squeel Order
  def sort
    binding.pry
    if params[:bUseDefaultSort] == 'true'
      column = self.columns.select{|c|c.name == self.initial_ordering.keys.first.to_s}.first
      directions = self.initial_ordering.values.first.to_s == "asc" ? 1 : -1
    else
      column = self.columns[params[:iSortCol_0].to_i]
      direction = params[:sSortDir_0] == "asc" ? 1 : -1
    end
    if column.sortable
      Squeel::Nodes::KeyPath.new(column.column_source.split('.') << Squeel::Nodes::Order.new(Squeel::Nodes::Stub.new(column.method), direction))
    end
  end

end