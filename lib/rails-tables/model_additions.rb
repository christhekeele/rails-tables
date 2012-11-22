def has_datatable(*args)
  arguments = args.pop || {}
  name = arguments.fetch(:name, 'datatable')
  klass = arguments.fetch(:klass, "#{self.name.pluralize.underscore}_datatable").camelize
  cattr_accessor name
  self.send("#{name}=", klass.constantize.new(name, self))
end