class Datatable
  delegate :params, to: 'self.view'

attr_accessor :name, :model
  def initialize(name, model)
    self.name = name
    self.model = model
  end

class_attribute :source
  def self.source_path=(source)
    self.source = Rails.application.routes.url_helpers.send(source, format: "json")
  end

class_attribute :initial_orderings
  def self.initial_ordering(orderings)
    self.set_initial_orderings orderings
  end
  def self.set_initial_orderings(orderings)
    self.initial_orderings = {} if self.initial_orderings.nil?
    self.initial_orderings.merge! orderings
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

attr_accessor :view, :scopes
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

class_attribute :columns, :column_factory
  def self.column(name, *args)
    arguments = args.pop || {}
    self.column_factory = [] if self.column_factory.nil?
    self.column_factory << { name: name, args: arguments }
  end
  def columns
    @columns ||= self.column_factory.map{ |new_column| Column.new(self.model, new_column[:name], new_column[:args]) }
  end

class_attribute :match_any
  self.match_any = true
  def self.match_all_columns
    self.match_any = false
  end

attr_accessor :joins
  def joins
    @joins ||= self.columns.map(&:column_source).uniq.reject(&:blank?)
  end
attr_accessor :searches
  def searches
    @searches ||= self.columns.select(&:searchable).select{|c| c.column_source.present?}
  end

private

  def objects
    query = self.model
    self.joins.each do |join|
      query = query.uniq.includes{ join.split('.').inject((strs.present? ? self : nil), :__send__).outer }
    end
    if sortable
      sort_expression = sort
      query = query.reorder{ my{sort_expression} }#("#{sort_column} #{sort_direction}")
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
  
  def sortable
    self.columns.map{ |column| column.sortable }[params[:iSortCol_0].to_i] unless params[:bUseDefaultSort] == 'true'
  end
  def sort
    column = self.columns[params[:iSortCol_0].to_i]
    direction = params[:sSortDir_0] == "asc" ? 1 : -1
    Squeel::Nodes::KeyPath.new(column.column_source.split('.') << Squeel::Nodes::Order.new(column.method, direction))
  end

  def search(terms)
    terms = terms.split if terms.is_a? String
    self.searches.map do |column|
      terms.map do |word|
        Squeel::Nodes::KeyPath.new(column.column_source.split('.') << Squeel::Nodes::Stub.new(column.method)) =~ "%#{word}%"
      end.compact.inject(&:|)
    end.compact.inject(&:|)
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