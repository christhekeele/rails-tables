def has_datatable(*args)
  arguments = args.pop || {}
  name = arguments.fetch(:name, 'datatable')
  klass = arguments.fetch(:klass, "#{self.name.pluralize}Table")
  cattr_accessor name
  self.send("#{name}=", klass.constantize.new(name, self))
  self.class.instance_eval do
  	define_method "#{name}_search" do |params|
  		binding.pry
	  end
	end
end