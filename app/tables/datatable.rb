class Datatable
  delegate :params, to: 'self.view'

attr_accessor :name, :model
  def initialize(name, model)
    self.name = name
    self.model = model
  end

attr_accessor :view, :filters
  def render_with(view, *args)
    arguments = args.pop || {}
    self.view = view
    self.filters = arguments.fetch(:filters, {})
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

class_attribute :columns, :searches, :match_any
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
  def self.match_any_column(match_any=true)
    self.match_any = match_any
  end

private

  def objects
    if sortable
      objects = self.model.reorder("#{sort_column} #{sort_direction}")
    else
      objects = self.model
    end
    @filters.each do |method, arguments|
      objects = objects.send(method, arguments)
    end
    if params[:sSearch].present?
      objects = objects.send("#{self.name}_search", params[:sSearch])
      #objects = objects.where("name like :search or category like :search", search: "%#{params[:sSearch]}%")
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
    self.columns.map{ |column| column.sortable }[params[:iSortCol_0].to_i]
  end
  def sort_column
    self.columns.map(&:column_name)[params[:iSortCol_0].to_i]
  end
  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end

  def data
    objects.map do |object|
      self.columns.map{ |column| column.render(self.view, object) }
    end
  end

end