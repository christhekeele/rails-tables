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
    @joins ||= self.columns.map(&:relation_chain).uniq.reject(&:blank?)
  end

private

  def objects
    objects = self.model
    self.joins.each do |join|
      objects = objects.uniq.includes{ join.map(&:to_s).inject((strs.present? ? self : nil), :__send__).outer }
    end
    if sortable
      objects = objects.reorder("#{sort_column} #{sort_direction}")
    end
    self.scopes.each do |scope|
      objects = scope.call(objects)
    end
    if params[:sSearch].present?
      objects = objects.search(params[:sSearch])
    end
    objects = objects.paginate(page: page, per_page: per_page)
  end

  def search(terms)
    self.columns.select(&:searchable).map(&:column_source).each do |field|
    end
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end
  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end
  
  def sortable
    self.columns.map{ |column| column.sortable }[params[:iSortCol_0].to_i] unless params[:bUseDefaultSort] == 'true'
  end
  def sort_column
    self.columns.map(&:column_source)[params[:iSortCol_0].to_i]
  end
  def sort_direction
    params[:sSortDir_0] == "asc" ? "asc" : "desc"
  end

  def data
    objects.map do |object|
      self.columns.map{ |column| column.render(self.view, object) }
    end
  end

end