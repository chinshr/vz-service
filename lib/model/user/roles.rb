module Model::User::Roles
  ROLES = %w[user backend admin developer].collect(&:to_sym).freeze

  def self.included(base)
    base.send :extend, ClassMethods
    base.send :include, InstanceMethods
    base.send :attr_accessor, :creator
    base.send :before_validation, :create_role

    base.class_eval do
      validate  :validate_roles_assignment

      scope :any_of_roles, -> (roles) { where(roles_sql_condition(roles)) }
    end
  end

  module ClassMethods

    def get_role_mask(role)
      index = ROLES.index(role.to_sym)
      index ? 2**index : 0
    end

    def roles_sql_condition(*args)
      result = []
      Array.wrap(args).flatten.each do |role|
        result << "(users.roles_mask & #{get_role_mask(role)} > 0)"
      end
      result.length > 0 ? "(#{ result.join(" OR ") })" : "(1 = 1)"
    end
  end

  module InstanceMethods
    def roles=(roles_value)
      self.roles_mask = (Array.wrap(roles_value).map(&:to_sym) & ROLES).sum { |r| self.class.get_role_mask(r) }
    end

    def roles
      ROLES.reject {|r| ((roles_mask || 0) & self.class.get_role_mask(r)).zero?}
    end

    def highest_role
      roles.first # FIXME: should be highest
    end

    def user_role?
      roles.include?(:user) || roles.include?(:admin) ||
      roles.include?(:backend) || roles.include?(:developer)
    end

    def admin_role?
      roles.include?(:admin)
    end

    def backend_role?
      roles.include?(:backend) || roles.include?(:admin)
    end

    def developer_role?
      roles.include?(:developer) || roles.include?(:admin)
    end

    private

    def create_role
      self.roles = ['user'] if self.roles.blank?
    end

    def validate_roles_assignment
      return
      #validate only if there was actual change
      if new_record? || changed_attributes["roles_mask"]
        if creator.blank? && roles != [:user]
          self.errors.add(:roles, I18n.t('activerecord.errors.models.account.attributes.roles.validate_roles_assignment'))
        elsif creator && !creator.roles.include?(:admin)
          self.errors.add(:roles, I18n.t('activerecord.errors.models.account.attributes.roles.validate_admin_assignment'))
        elsif creator && creator.roles.include?(:admin) && self == creator
          self.errors.add(:roles, I18n.t('activerecord.errors.models.account.attributes.roles.validate_self_assignment'))
        end
      end
    end

  end
end
