class VehicleAssignmentPolicy < ApplicationPolicy
  def new?
    create?
  end

  def create?
    user.admin? || user.superadmin?
  end

  def destroy?
    user.admin? || user.superadmin?
  end

  def index?
    user.admin? || user.analista? || user.superadmin?
  end

  def show?
    user.admin? || user.analista? || user.superadmin?
  end
end
