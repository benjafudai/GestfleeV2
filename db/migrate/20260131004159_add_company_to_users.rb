class AddCompanyToUsers < ActiveRecord::Migration[7.1]
  def up
    add_reference :users, :company, null: true, foreign_key: true

    # Create default company if it doesn't exist (using raw SQL or model)
    # Using model is easier here since we just generated it
    Company.reset_column_information
    default_company = Company.create_with(rut: '77.777.777-7').find_or_create_by(name: 'Empresa Principal')

    User.update_all(company_id: default_company.id)

    change_column_null :users, :company_id, false
  end

  def down
    remove_reference :users, :company
  end
end
