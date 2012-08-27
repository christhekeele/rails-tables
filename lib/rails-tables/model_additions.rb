def has_datatable(*args)
  arguments = args.pop || {}
  name = arguments.fetch(:name, 'datatable')
  klass = arguments.fetch(:klass, "#{self.name.pluralize}Table")
  require File.join(Rails.root, 'app', 'tables', "#{klass.underscore}.rb")
  model = self
  klass.constantize.class.send(:define_method, 'model') do
    model
  end
  self.class.send(:define_method, name) do
    klass.constantize
  end
end  