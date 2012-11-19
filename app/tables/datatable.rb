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

class_attribute :defaults
self.defaults = {
  initial_orderings: {},
}
  def self.initial_ordering(orderings)
    self.initial_orderings orderings
  end
  def self.initial_orderings(orderings)
    self.defaults[:initial_orderings].merge! orderings
  end

  def html_data
    options = {}
    if self.class.source?
      options[:source] = self.class.source
    end
    if self.defaults.has_key? :initial_orderings
      self.class.defaults[:initial_orderings].each do |column, order|
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

class_attribute :columns, :searches, :authorized_scopes, :match_any
  def self.column(name, *args)
    arguments = args.pop || {}
    self.columns = [] if self.columns.nil?
    self.columns << Column.new(name, arguments)
  end
  def self.search_by(name, *args)
    arguments = args.pop || {}
    self.searches = [] if self.searches.nil?
    self.searches << Search.new(name, self, arguments)
  end
  self.match_any = true
  def self.match_all_columns
    self.match_any = false
  end

private

  def objects
    if sortable
      objects = self.model.reorder("#{sort_column} #{sort_direction}")
    else
      objects = self.model
    end
    self.scopes.each do |scope|
      objects = scope.call(objects)
    end
    if params[:sSearch].present?
      objects = objects.send("#{self.name}_search", params[:sSearch])
    end
    objects = objects.paginate(page: page, per_page: per_page)
    objects
  end

  def search(objects, terms)
    self.searches.each do |search|
      objects = search.search(objects, terms)
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
    self.columns.map(&:column_name)[params[:iSortCol_0].to_i]
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