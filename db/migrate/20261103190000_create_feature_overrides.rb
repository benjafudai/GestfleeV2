class CreateFeatureOverrides < ActiveRecord::Migration[8.1]
  def change
    # Secciones de la app que el superadmin apaga o enciende por empresa o por
    # usuario. Sin fila, la sección está activa (así nada cambia para las
    # empresas que ya existen). expires_on permite, por ejemplo, una prueba.
    create_table :feature_overrides do |t|
      t.references :subject, polymorphic: true, null: false
      t.string :feature, null: false
      t.boolean :enabled, null: false
      t.date :expires_on
      t.references :granted_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :feature_overrides, [:subject_type, :subject_id, :feature], unique: true,
              name: "index_feature_overrides_on_subject_and_feature"
  end
end
