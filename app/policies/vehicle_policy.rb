class VehiclePolicy < ApplicationPolicy
  def index?
    user.admin? || user.analista? || user.superadmin?
  end

  def show?
    user.admin? || user.analista? || user.superadmin?
  end

  def create?
    user.admin? || user.superadmin?
  end

  def update?
    user.admin? || user.superadmin?
  end

  def destroy?
    user.admin? || user.superadmin?
  end

  # Crear planes y repuestos desde la biblioteca: quien edita el vehículo.
  def generate_plan?
    update?
  end
end