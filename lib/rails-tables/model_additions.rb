def has_datatable(*args)
  arguments = args.pop || {}
  name = arguments.fetch(:name, 'datatable')
  klass = arguments.fetch(:klass, "#{self.name.pluralize}Datatable")
  cattr_accessor name
  self.send("#{name}=", klass.constantize.new(name, self))
  self.class.instance_eval do
    define_method "#{name}_search" do |terms|
      searches =
        self.datatable.searches.map do |search|
          self.instance_exec search.column_name, terms, &search.search
        end.inject do |t, expr|
          if self.datatable.match_any
            t | expr
          else
            t & expr
          end
        end
      self.where{ searches }
    end
  end
end