class ChecklistSubmissionPolicy < ApplicationPolicy
  def index?
    user.admin? || user.chofer? || user.analista? || user.superadmin?
  end

  def show?
    same_company? && (user.admin? || user.analista? || user.superadmin? || (user.chofer? && record.user == user))
  end

  def create?
    user.chofer?
  end

  def review?
    same_company? && (user.admin? || user.superadmin?)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.superadmin?
        scope.all
      elsif user.admin? || user.analista?
        scope.where(company_id: user.company_id)
      elsif user.chofer?
        scope.for_chofer(user)
      else
        scope.none
      end
    end
  end
end
