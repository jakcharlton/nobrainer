module NoBrainer::Document::Validation
  extend ActiveSupport::Concern
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks

  # TODO Test that thing
  def valid?(context=nil)
    super(context || (new_record? ? :create : :update))
  end

  module ClassMethods
    def validates_uniqueness_of(*attr_names)
      validates_with UniquenessValidator, _merge_attributes(attr_names)
    end

    def validates_presence_of(*attr_names)
      validates_with PresenceValidator, _merge_attributes(attr_names)
    end
  end

  class UniquenessValidator < ActiveModel::EachValidator
    def validate_each(doc, attr, value)
      criteria = doc.root_class.unscoped.where(attr => value)
      criteria = apply_scopes(criteria, doc)
      criteria = exclude_doc(criteria, doc) if doc.persisted?
      is_unique = criteria.count == 0
      doc.errors.add(attr, :taken, options.except(:scope).merge(:value => value)) unless is_unique
      is_unique
    end

    def apply_scopes(criteria, doc)
      criteria.where([*options[:scope]].map { |k| {k => doc.read_attribute(k)} })
    end

    def exclude_doc(criteria, doc)
      criteria.where(:id.ne => doc.id)
    end
  end

  class PresenceValidator < ActiveModel::EachValidator
    def validate_each(doc, attr, value)
      if value.respond_to?(:persisted?) && !value.persisted?
        NoBrainer.logger.warn "Validating the presence of '#{attr}' in a #{doc.class} failed because '#{attr}' was not persisted"
        NoBrainer.logger.warn "This can be fixed by saving '#{attr}' before the #{doc.class}."
        value = nil
      end
      doc.errors.add(attr, :blank, options) if value.blank?
    end
  end

end
