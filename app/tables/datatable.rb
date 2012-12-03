class Datatable
  include Datatable::Sorting
  include Datatable::Searching
  delegate :params, to: 'self.view'

  attr_accessor :name, :root, :model, :view, :scopes

  # Called in has_datatable for model, or on an ActiveRecord::Relation in method_missing
  def initialize(name, root)
    self.name = name
    self.root = root
    self.model = root.respond_to?(:klass) ? root.klass : root
  end

  # Render data attributes for table for view
  def html_data
    options = {}
    if self.class.source?
      options[:source] = self.class.source
    end
    unless self.initial_orderings.nil?
      self.class.initial_orderings.each do |column, order|
        options["#{column}_ordering".to_sym] = order.to_s
      end
    end
    options[:unsorted] = 'true'
    options
  end

  # Pass in view and scope table for controller
  def render_with(view)
    self.view = view
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
    self.source_factory = source
  end
  def self.source
    @source ||= Rails.application.routes.url_helpers.send(self.source_factory, format: "json")
  end

  class_attribute :columns, :column_factory
  # Allow user defined columns, lazily instanciate later after 'self.root' is defined
  def self.column(name, *args)
    arguments = args.pop || {}
    self.column_factory = [] if self.column_factory.nil?
    self.column_factory << { name: name.to_s, args: arguments }
  end
  # Lazily instanciates and caches columns
  def columns
    @columns ||= self.column_factory.map{ |new_column| Column.new(self, new_column[:name], new_column[:args]) }
  end

  class_attribute :joins
  self.joins = []
  # Allow user to explicitly join tables (not sure of use case)
  def self.join(join)
    self.joins += [join.to_s]
  end
  # Deduce joins based on columns and explicitly joined tables 
  def joins
    @joins ||= (self.columns.reject(&:virtual).map(&:column_source).reject(&:blank?) + self.class.joins).uniq 
  end

private

  # Compose query to fetch objects from database
  def objects
    query = self.root.uniq
    self.joins.each do |join|
      query = query.joins{ join.split('.').inject((join.present? ? self : nil), :__send__).outer }
      # query = query.includes{ join.split('.').inject((join.present? ? self : nil), :__send__).outer }
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
      self.columns.map{ |column| column.render(self.view, object) }
    end
  end

end