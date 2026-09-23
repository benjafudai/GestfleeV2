class MaintenancePlanPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      company_scoped
    end
  end

  # Ver planes: admin, superadmin y mecánico (los necesita para las OT).
  def index?
    user.superadmin? || user.admin? || user.mecanico?
  end

  def show?
    index?
  end

  # Definir/editar/eliminar planes: solo admin (ver roadmap — es tarea de admin).
  def create?
    user.superadmin? || user.admin?
  end

  def update?
    create?
  end

  def destroy?
    create?
  end
end
