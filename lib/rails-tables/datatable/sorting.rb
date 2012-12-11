module RailsTables::Sorting
  extend ActiveSupport::Concern

  included do
    class_attribute :initial_order
    extend ClassMethods
  end

  module ClassMethods
    # Gotta set these to fight against datatables' default ordering on first column
    def initial_ordering(orderings)
      self.initial_order = orderings
    end

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
    if params[:bUseDefaultSort] == 'true' and self.initial_order.present?
      column = self.columns.select{|c|c.name == self.initial_order.keys.first.to_s}.first
      direction = self.initial_order.values.first.to_s == "asc" ? 1 : -1
    else
      column = self.columns[params[:iSortCol_0].to_i]
      direction = params[:sSortDir_0] == "asc" ? 1 : -1
    end
    if column.sortable
      Squeel::Nodes::KeyPath.new(column.column_source.split('.') << Squeel::Nodes::Order.new(Squeel::Nodes::Stub.new(column.method), direction))
    end
  end

end