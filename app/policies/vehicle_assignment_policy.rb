class VehicleAssignmentPolicy < ApplicationPolicy
  def new?
    create?
  end

  def create?
    user.admin?
  end

  def destroy?
    user.admin?
  end

  def index?
    user.admin? || user.analista?
  end

  def show?
    user.admin? || user.analista?
  end
end
