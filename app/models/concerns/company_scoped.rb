module CompanyScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :company
    before_validation :assign_company

    # Current.company es nil para superadmin (no pertenece a ninguna empresa).
    # En ese caso no filtramos (ve todo), en vez de generar "WHERE company_id IS NULL"
    # que nunca traería resultados sobre una columna NOT NULL.
    default_scope { Current.company ? where(company: Current.company) : all }
  end

  private

  def assign_company
    self.company ||= Current.company
  end
end
