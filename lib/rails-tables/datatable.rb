require "rails-tables/datatable/column"
require "rails-tables/datatable/sorting"
require "rails-tables/datatable/searching"
class RailsTables::Datatable
  include RailsTables::Sorting
  include RailsTables::Searching
  delegate :params, to: 'self.view'

  attr_accessor :name, :root, :model, :view, :locals

  # Called in has_datatable for model, or on an ActiveRecord::Relation in method_missing
  def initialize(name, model)
    self.name = name
    self.root = self.model = model
  end

  def set_root(root)
    self.root = root
    self
  end

  # Render data attributes for table for view
  def html_data
    options = {}
    if self.class.source?
      options[:source] = self.class.source
    end
    if self.initial_order.present?
      options[:order_column] = self.columns.select{|c|c.name==self.class.initial_order.first[0].to_s}.first.index
      options[:order_direction] = self.class.initial_order.first[1]
    end
    options[:unsorted] = 'true'
    options
  end

  # Pass in view and scope table for controller
  def render_with(view, locals={})
    self.view = view
    self.locals = locals
    return self
  end

  # Format this table for controller's response
  def as_json(options={})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: objects.size,
      iTotalDisplayRecords: objects.total_entries,
      aaData: data
    }
  end

  class_attribute :source, :source_factory
  # Set source url for this table
  def self.source_path=(source)
    self.source_factory = source if source.present?
  end
  def self.source
    @source ||= Rails.application.routes.url_helpers.send(self.source_factory, format: "json") if self.source_factory.present?
  end

  class_attribute :columns, :column_factory
  # Allow user defined columns, lazily instanciate later after 'self.root' is defined
  def self.column(name, options={}, &block)
    self.column_factory = [] if self.column_factory.nil?
    self.column_factory << { name: name.to_s, block: block }.merge(options)
  end
  # Lazily instanciates and caches columns
  def columns
    @columns ||= self.column_factory.map.with_index do |new_column, index|
      new_column[:index] = index
      new_column[:table] = self
      new_column[:model] = self.model
      RailsTables::ColumnBuilder.define(new_column)
    end
  end

  class_attribute :joins
  self.joins = []
  # Allow user to explicitly join tables (not sure of use case)
  def self.join(join)
    self.joins += [join.to_s]
  end
  # Deduce joins based on columns and explicitly joined tables
  def joins
    @joins ||= (self.columns.reject(&:virtual).map(&:column_source).reject(&:blank?).map(&:to_s) + self.class.joins).uniq
  end

private

  # Compose query to fetch objects from database
  def objects
    query = self.root.uniq
    self.joins.each do |join|
      query = query.joins{ join.split('.').inject((join.present? ? self : nil), :__send__).outer }
      query = query.includes{ join.split('.').inject((join.present? ? self : nil), :__send__).outer }
    end
    query = query.reorder{ my{sort} } if sortable
    query = query.where{ my{search(params[:sSearch])} } if searchable
    query = query.paginate(page: page, per_page: per_page)
  end

  # Pagination doesn't merit it's own module.
  def page
    params[:iDisplayStart].to_i/per_page + 1
  end
  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  # Generate HTML for each row
  def data
    objects.map do |object|
      self.columns.map{ |column| column.render(object) }
    end
  end

end