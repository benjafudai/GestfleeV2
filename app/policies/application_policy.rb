# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  private

  # Defensa en profundidad: además del default_scope de CompanyScoped, cada
  # policy que muestre/edite un registro puntual debería confirmar que es de
  # la empresa del usuario. superadmin no pertenece a ninguna empresa y ve todo.
  def same_company?
    return true if user.superadmin?
    return false unless record.respond_to?(:company_id)
    record.company_id == user.company_id
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope

    # Para Scopes de modelos con CompanyScoped: superadmin ve todo, el resto
    # solo su empresa. No reemplaza roles/condiciones adicionales del Scope.
    def company_scoped
      user.superadmin? ? scope.all : scope.where(company_id: user.company_id)
    end
  end
end
