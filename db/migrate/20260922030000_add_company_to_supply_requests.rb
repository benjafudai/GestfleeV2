class AddCompanyToSupplyRequests < ActiveRecord::Migration[7.1]
  def up
    add_reference :supply_requests, :company, foreign_key: true

    execute <<~SQL
      UPDATE supply_requests
      SET company_id = vehicles.company_id
      FROM vehicles
      WHERE supply_requests.vehicle_id = vehicles.id
    SQL

    change_column_null :supply_requests, :company_id, false
  end

  def down
    remove_reference :supply_requests, :company, foreign_key: true
  end
end
