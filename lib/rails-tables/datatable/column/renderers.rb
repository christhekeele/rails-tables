module RailsTables
  module Renderers
    def link_to_object(object)
      property = object.try(:send, column_name)
      link_to property, object if not property.nil?
    end
    def link_to_objects(objects)
      objects.reject(&:blank?).map{ |object| related_link(object).strip }.join(', ') if not objects.nil?
    end

    def time(object)
      property = object.try(:send, column_name)
      property.strftime("%I:%M%p") if not property.nil?
    end
    def date(object)
      property = object.try(:send, column_name)
      property.strftime("%m/%d/%Y") if not property.nil?
    end
    def datetime(object)
      property = object.try(:send, column_name)
      property.strftime("%m/%d/%Y at %I:%M%p") if not property.nil?
    end

    def currency(object)
      property = object.try(:send, column_name)
      number_to_currency(property.to_f) if not property.nil?
    end
    def phone(object)
      property = object.try(:send, column_name)
      number_to_phone(property.to_f) if not property.nil?
    end

    def truncate(object)
      property = object.try(:send, column_name)
      truncate(property, 50) if not property.nil?
    end
  end
end