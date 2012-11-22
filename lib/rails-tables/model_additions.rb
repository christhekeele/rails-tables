def has_datatable(*args)
  arguments = args.pop || {}
  name = arguments.fetch(:name, 'datatable')
  klass = arguments.fetch(:klass, "#{self.name.pluralize.underscore}_datatable").camelize
  cattr_accessor name
  self.send("#{name}=", klass.constantize.new(name, self))
  self.class.instance_eval do
    define_method "#{name}_search" do |terms|
      datatable = self.send(__method__.slice '_search')
      searches =
        datatable.columns.select(&:searchable).map(&:column_source).each do |field|
          self.instance_exec search.column_name, terms, &search.search
        end.inject do |t, expr|
          if self.datatable.match_any
            t | expr
          else
            t & expr
          end
        end
      Proc.new do |field, terms|
        if self.class.split_search_terms
          terms = terms.split
        else
          terms = [terms]
        end
        terms.map{|s| '%%%s%%' % s}.map do |term|
          Squeel::Nodes::Predicate.new(Squeel::Nodes::Stub.new(field), :matches, term)
        end.inject do |t, expr|
          if self.class.match_any
            t | expr
          else
            t & expr
          end
        end
      end
    end
      self.where{ searches }
    end
  end
end