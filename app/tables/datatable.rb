class Datatable
  include Datatable::Sorting
  include Datatable::Searching
  delegate :params, to: 'self.view'

  attr_accessor :name, :model
  attr_accessor :view, :scopes
  def initialize(name, model)
    self.name = name
    self.model = model
  end

  def html_data
    options = {}
    if self.class.source?
      options[:source] = self.class.source
    end
    unless self.initial_orderings.nil?
      self.class.initial_orderings.each do |column, order|
        options["#{column}_ordering"] = order.to_s
      end
    end
    options[:unsorted] = 'true'
    options
  end

  def render_with(view, *args)
    arguments = args.pop || {}
    self.view = view
    self.scopes = Array(arguments.fetch(:scopes, []))
    return self
  end

  def as_json(options={})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: objects.size,
      iTotalDisplayRecords: objects.total_entries,
      aaData: data
    }
  end

  class_attribute :source
  def self.source_path=(source)
    self.source = Rails.application.routes.url_helpers.send(source, format: "json")
  end

  class_attribute :columns, :column_factory
  def self.column(name, *args)
    arguments = args.pop || {}
    self.column_factory = [] if self.column_factory.nil?
    self.column_factory << { name: name, args: arguments }
  end
  def columns
    @columns ||= self.column_factory.map{ |new_column| Column.new(self.model, new_column[:name], new_column[:args]) }
  end

  class_attribute :joins
  self.joins = []
  def self.join(join)
    self.joins += [join.to_s]
  end
  def joins
    @joins ||= (self.columns.reject(&:virtual).map(&:column_source).reject(&:blank?) + self.class.joins).uniq 
  end

private

  def objects
    query = self.model.uniq
    self.joins.each do |join|
      query = query.joins{ join.split('.').inject((join.present? ? self : nil), :__send__).outer }
      query = query.includes{ join.split('.').inject((join.present? ? self : nil), :__send__).outer }
    end
    if sortable
      sort_expression = sort
      query = query.reorder{ my{sort_expression} }
    end
    self.scopes.each do |scope|
      query = scope.call(query)
    end
    if params[:sSearch].present?
      search_expression = search(params[:sSearch])
      query = query.where{ my{search_expression} }
    end
    query = query.paginate(page: page, per_page: per_page)
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end
  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def data
    objects.map do |object|
      self.columns.map{ |column| column.render(self.view, object) }
    end
  end

end