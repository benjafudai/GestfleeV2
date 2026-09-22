class ChecklistSubmissionPolicy < ApplicationPolicy
  def index?
    user.admin? || user.chofer? || user.analista?
  end

  def show?
    user.admin? || user.analista? || (user.chofer? && record.user == user)
  end

  def create?
    user.chofer?
  end

  def review?
    user.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.analista?
        scope.for_company
      elsif user.chofer?
        scope.for_chofer(user)
      else
        scope.none
      end
    end
  end
end
