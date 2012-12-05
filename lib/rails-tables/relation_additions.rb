module RailsTables::RelationAdditions

  delegate :has_datatable?, to: :klass

  def respond_to?(method, include_private = false)
    if self.has_datatable? method.to_s
      true
    else
      super
    end
  end

protected

  def method_missing(method, *args, &block)
    if self.has_datatable? method.to_s
      self.klass.send(method.to_s).set_root(self)
    else
      super
    end
  end

end

ActiveRecord::Relation.send :include, RailsTables::RelationAdditions