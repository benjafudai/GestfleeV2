# Comprobante de entrega: quién recibió los productos. La foto va como adjunto (Active Storage).
class AddRecipientToDeliveries < ActiveRecord::Migration[8.1]
  def change
    add_column :deliveries, :recipient_name, :string
    add_column :deliveries, :recipient_rut, :string
    add_column :deliveries, :recipient_relation, :string
  end
end
