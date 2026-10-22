# Entregas de productos: el chofer registra y ve las suyas; admin, bodeguero y
# analista ven todas las de la empresa; admin y bodeguero pueden anularlas.
class DeliveryPolicy < ApplicationPolicy
  def index?
    user.superadmin? || user.admin? || user.bodeguero? || user.analista? || user.chofer?
  end

  def show?
    return false unless index? && same_company?

    user.chofer? ? record.driver_id == user.id : true
  end

  def create?
    user.company.present? && (user.chofer? || user.admin? || user.bodeguero?)
  end

  def cancel?
    (user.admin? || user.bodeguero?) && same_company? && record.delivered?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.chofer?
        company_scoped.where(driver_id: user.id)
      elsif user.superadmin? || user.admin? || user.bodeguero? || user.analista?
        company_scoped
      else
        scope.none
      end
    end
  end
end
