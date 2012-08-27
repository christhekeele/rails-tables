class Datatable
  delegate :params, to: 'self.view'
  
  attr_accessor :view, :filters
  def initialize(view, filters={})
    self.view = view
    self.filters = filters
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: objects.size,
      iTotalDisplayRecords: objects.total_entries,
      aaData: data
    }
  end

  class << self
    attr_accessor :columns, :searches
    def column(name, *args)
      arguments = args.pop || {}
      self.columns = [] if self.columns.nil?
      self.columns << Column.new(name, arguments)
    end
    # def search_by(name, *args)
    #   arguments = args.pop || {}
    #   self.searches = [] if self.searches.nil?
    #   self.searches << Search.new(name, self.table, arguments)
    # end
  end

private

  def objects
    if sortable
      objects = self.class.model.reorder("#{sort_column} #{sort_direction}")
    else
      objects = self.class.model
    end
    @filters.each do |method, arguments|
      objects = objects.send(method, arguments)
    end
    # if params[:sSearch].present?
    #   objects = self.model(:datatable_search, search(objects, params[:sSearch]))
    #   #objects = objects.where("name like :search or category like :search", search: "%#{params[:sSearch]}%")
    # end
    objects = objects.paginate(page: page, per_page: per_page)
    objects
  end

  def search(objects, terms)
    self.class.searches.each do |search|
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
    self.class.columns.map{ |column| column.sortable }[params[:iSortCol_0].to_i]
  end
  def sort_column
    self.class.columns.map(&:column_name)[params[:iSortCol_0].to_i]
  end
  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end

  def data
    objects.map do |object|
      self.class.columns.map{ |column| column.render(self.view, object) }
    end
  end

end