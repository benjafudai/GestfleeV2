class VehiclePolicy < ApplicationPolicy
  def index?
    user.admin? || user.analista?
  end

  def show?
    user.admin? || user.analista?
  end

  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end
end