module RailsTables::RelationAdditions

  delegate :has_datatable?, to: :klass

  def respond_to?(method, include_private = false)
    self.has_datatable? method
  end

protected

  def method_missing(method, *args, &block)
    if self.has_datatable? method.to_s
      self.klass.datatables[method.to_s].new(method.to_s, self)
    else
      super
    end
  end

end

ActiveRecord::Relation.send :include, RailsTables::RelationAdditions