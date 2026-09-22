class AddCompanyToPartFitments < ActiveRecord::Migration[7.1]
  def up
    add_reference :part_fitments, :company, foreign_key: true

    execute <<~SQL
      UPDATE part_fitments
      SET company_id = parts.company_id
      FROM parts
      WHERE part_fitments.part_id = parts.id
    SQL

    change_column_null :part_fitments, :company_id, false
  end

  def down
    remove_reference :part_fitments, :company, foreign_key: true
  end
end
