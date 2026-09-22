class AddCompanyToChecklistSubmissions < ActiveRecord::Migration[7.1]
  def up
    add_reference :checklist_submissions, :company, foreign_key: true

    # Backfill desde el vehículo de cada envío existente.
    execute <<~SQL
      UPDATE checklist_submissions
      SET company_id = vehicles.company_id
      FROM vehicles
      WHERE checklist_submissions.vehicle_id = vehicles.id
    SQL

    change_column_null :checklist_submissions, :company_id, false
  end

  def down
    remove_reference :checklist_submissions, :company, foreign_key: true
  end
end
