def has_datatable(*args)
  arguments = args.pop || {}
  name = arguments.fetch(:name, 'datatable')
  klass = arguments.fetch(:klass, "#{self.name.pluralize.underscore}_datatable").camelize
  cattr_accessor name
  self.send("#{name}=", klass.constantize.new(name, self))
  # self.class.instance_eval do
  #   define_method "#{name}_search" do |terms|
  #     datatable = self.send(__method__[0, __method__.to_s.index('_search')])
  #     query = self
  #     datatable.columns.select(&:searchable).map(&:column_source).each do |column|
  #       terms.split.each do |word|
  #         query.where{ Squeel::Nodes::Predicate.new(Squeel::Nodes::KeyPath.new([Squeel::Nodes::Stub.new(column)], true), :matches, '%%%s%%' % word) }
  #       end
  #     end
  #     query
  #   end
  # end
end