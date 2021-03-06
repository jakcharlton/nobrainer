module NoBrainer::Criteria::Termination::Update
  extend ActiveSupport::Concern

  def update_all(attrs={}, &block)
    block = proc { attrs } unless block_given?
    run(to_rql.update(&block))['replaced']
  end

  def replace_all(attrs={}, &block)
    block = proc { attrs } unless block_given?
    run(to_rql.replace(&block))['replaced']
  end
end
