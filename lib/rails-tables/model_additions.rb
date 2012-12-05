module RailsTables::ModelAdditions
  extend ActiveSupport::Concern

  included do
    extend ClassMethods
  end

  module ClassMethods

    def has_datatable(*args)
      arguments = { }
      if args.present?
        if args.first.is_a? Hash
          arguments = args.pop
        else
          arguments[:name] = args.first if args.try(:first)
          arguments[:klass] = args.second if args.try(:second)
        end
      end
      name = arguments.fetch(:name, 'datatable').to_s
      klass = arguments.fetch(:klass, "#{self.name.pluralize.underscore}_datatable").to_s.camelize
      klass = klass.constantize

      cattr_accessor :datatables unless self.respond_to? :datatables
      self.datatables ||= {}

      if self.has_datatable? name
        raise RailsTables::NameError,
          "#{self.name} already has a datatable with the name '#{name}'. "\
          "Please supply a :name parameter to has_datatable other than: #{self.datatables.keys.join(', ')}"
      else
        self.datatables[name] = klass
        cattr_writer name
        self.send("#{name}=", klass.new(name, self))
        self.class.instance_eval do
          define_method name do
            self.class_variable_get("@@#{name}").set_root(self)
          end
        end
      end
    end

    def has_datatable?(table_name=:datatable)
      self.respond_to? :datatables and self.datatables.keys.include? table_name.to_s
    end

  end

# InstanceMethods

end

ActiveRecord::Base.send :include, RailsTables::ModelAdditions