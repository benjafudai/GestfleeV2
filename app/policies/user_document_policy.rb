class UserDocumentPolicy < ApplicationPolicy
  def index?
    admin_or_superadmin?
  end

  def show?
    admin_or_superadmin? || record.user_id == user.id
  end

  def new?
    admin_or_superadmin?
  end

  def create?
    admin_or_superadmin?
  end

  def edit?
    admin_or_superadmin?
  end

  def update?
    admin_or_superadmin?
  end

  def destroy?
    admin_or_superadmin?
  end

  class Scope < Scope
    def resolve
      if user.superadmin?
        scope.all
      elsif user.admin?
        scope.joins(:user).where(users: { company_id: user.company_id })
      else
        scope.where(user_id: user.id)
      end
    end
  end

  private

  def admin_or_superadmin?
    user.admin? || user.superadmin?
  end
end
