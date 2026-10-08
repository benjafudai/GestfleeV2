# Quien puede editar el catálogo de repuestos puede registrar y borrar cotizaciones.
class PartQuotePolicy < ApplicationPolicy
  def create?
    (user.superadmin? || user.admin? || user.bodeguero?) && same_company?
  end

  def destroy?
    create?
  end
end
