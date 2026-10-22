# Resumen semanal: lo configuran y descargan los administradores de cada empresa.
class WeeklySummaryPolicy < ApplicationPolicy
  def show?
    user.admin? && user.company.present?
  end

  def update?
    show?
  end

  def deliver?
    show?
  end
end
