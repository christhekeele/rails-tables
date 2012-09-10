class Search
  cattr_accessor :strategies
  self.strategies = {
    contains_strategy: {
      type: :string,
      match_with: '%%%s%%'
    },
    starts_with_strategy: {
      type: :string,
      match_with: '%s%%'
    },
    ends_with_strategy: {
      type: :string,
      match_with: '%%%s'
    }
  }
  attr_accessor :name, :table, :column_name, :search_with, :match_any, :split_terms
  def initialize(name, table, *args)
    self.name = name
    self.table = table

    attributes = args.pop || {}
    self.column_name = attributes.fetch(:column_name, name)
    self.search_with = attributes.fetch(:search_with, :contains_strategy)
    self.match_any = attributes.fetch(:match_any, true)
    self.split_terms = attributes.fetch(:split_terms, true)

    
    define_singleton_method :search do
      if self.search_with.kind_of? Symbol
        strategy_builder(self.search_with, self.match_any, self.split_terms)
      else
        self.search_with(self.match_any, self.split_terms)
      end
    end
  end

  def strategy_builder(strategy_name, match_any, split_terms)
    Proc.new do |field, terms|
      if split_terms
        terms = terms.split
      else
        terms = [terms]
      end
      terms.map{|s| Search.strategies[strategy_name][:match_with] % s}.map do |term|
        Squeel::Nodes::Predicate.new(Squeel::Nodes::Stub.new(field), :matches, term)
      end.inject do |t, expr|
        if match_any
          t | expr
        else
          t & expr
        end
      end
    end
  end
end