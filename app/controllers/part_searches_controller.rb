# "Buscar repuesto": cruza lo que la empresa ya tiene en bodega (con su mejor
# cotización) con enlaces a tiendas externas, armados con marca, modelo y año
# del vehículo elegido.
class PartSearchesController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize :part_search

    @vehicles = Vehicle.order(:plate)
    @vehicle = @vehicles.find_by(id: params[:vehicle_id]) if params[:vehicle_id].present?
    @query = params[:q].to_s.squish

    return if @query.blank?

    # Cada palabra tiene que aparecer en el nombre o el SKU, en cualquier orden:
    # "filtro aceite" encuentra "Filtro de aceite".
    parts = policy_scope(Part)
    @query.split.first(6).each do |word|
      parts = parts.where("parts.name ILIKE :p OR parts.sku ILIKE :p", p: "%#{Part.sanitize_sql_like(word)}%")
    end
    @parts = parts.includes(:part_quotes, :part_fitments).order(:name).limit(50)
    @external_query = [@query, @vehicle&.brand, @vehicle&.model, @vehicle&.year].compact_blank.join(" ")
    @stores = PartStore.all
  end
end
