module RailsTables
  module Datatable
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

    module ClassMethods
      attr_accessor :columns
      def column(name, *args)
        arguments = args.pop || {}
        self.columns = [] if self.columns.nil?
        self.columns << Column.new(name, arguments)
      end
    end
    def self.included(base)
      base.extend ClassMethods
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
        terms = params[:sSearch].split.map{|s| s+="%"}
        columns = self.searches.keys.map(&:to_s)
        objects = objects.full_text_search(columns, terms)
        #objects = objects.where("name like :search or category like :search", search: "%#{params[:sSearch]}%")
      end
      objects = objects.paginate(page: page, per_page: per_page)
      objects
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

    class Column

      attr_accessor :name, :column_name, :referring_column_name, :render_with, :sortable, :default
      def initialize(name, *args)
        self.name = name

        attributes = args.pop || {}
        self.column_name = attributes.fetch(:column_name, name)
        self.referring_column_name = attributes.fetch(:referring_column_name, nil)
        self.render_with = attributes.fetch(:render_with, :default_render)
        self.sortable = attributes.fetch(:sortable, true)
        self.default = attributes.fetch(:default, '&ndash;')

        define_singleton_method :render do |view, object|
          if self.render_with.kind_of? Symbol
            content = self.send(self.render_with, view, object)
          else
            content = self.render_with.call(view, object)
          end
          content.present? ? content.to_s.html_safe : self.default
        end
      end

      def default_render(view, object)
        property = object.send(self.column_name)
        property if not property.nil?
      end
      def self_referential_link(view, object)
        property = object.send(self.column_name)
        view.link_to property, object if not property.nil?
      end
      def related_link(view, object)
        property = object.send(self.column_name)
        view.link_to self.name, property if not property.nil?
      end
      def related_link_list(view, object)
        property = object.send(self.referring_column_name)
        property.collect { |related_object| self_referential_link(view, related_object) }.join(', ') if not property.nil?
      end
      def time(view, object)
        property = object.send(self.column_name)
        property.strftime("%I:%M%p") if not property.nil?
      end
      def date(view, object)
        property = object.send(self.column_name)
        property.strftime("%m/%d/%Y") if not property.nil?
      end
      def datetime(view, object)
        property = object.send(self.column_name)
        property.strftime("%m/%d/%Y at %I:%M%p") if not property.nil?
      end

    end

  end
end