class AddConfigurationToCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :companies, :configuration, :jsonb, default: {}
  end
end
