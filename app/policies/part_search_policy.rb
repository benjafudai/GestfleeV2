# Búsqueda de repuestos: la ve quien puede ver el catálogo.
class PartSearchPolicy < ApplicationPolicy
  def show?
    PartPolicy.new(user, Part).index?
  end
end
