# Inventario comercial de la empresa: lo ven admin, bodeguero y analista;
# lo mueven admin y bodeguero; solo el admin borra productos.
class ProductPolicy < ApplicationPolicy
  def index?
    user.superadmin? || user.admin? || user.bodeguero? || user.analista?
  end

  def show?
    index? && same_company?
  end

  def create?
    user.company.present? && (user.admin? || user.bodeguero?)
  end

  def update?
    create? && same_company?
  end

  # Entradas, salidas y ajustes de stock.
  def move?
    update?
  end

  def destroy?
    user.admin? && same_company?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      allowed = user.superadmin? || user.admin? || user.bodeguero? || user.analista?
      allowed ? company_scoped : scope.none
    end
  end
end
