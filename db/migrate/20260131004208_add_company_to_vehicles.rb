class AddCompanyToVehicles < ActiveRecord::Migration[7.1]
  def up
    add_reference :vehicles, :company, null: true, foreign_key: true

    # We assume 'Empresa Principal' created in previous migration exists
    default_company = Company.find_by(name: 'Empresa Principal')
    
    if default_company
      Vehicle.update_all(company_id: default_company.id)
    end

    change_column_null :vehicles, :company_id, false
  end

  def down
    remove_reference :vehicles, :company
  end
end
