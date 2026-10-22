class DeliveriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_delivery, only: %i[show cancel]

  def index
    authorize Delivery
    deliveries = policy_scope(Delivery).includes(:driver, :vehicle, lines: :product)
    @drivers = current_user.chofer? ? [] : company_drivers
    @filters = params.permit(:driver_id, :status, :from, :to).to_h.compact_blank
    deliveries = deliveries.where(driver_id: @filters["driver_id"]) if @filters["driver_id"] && !current_user.chofer?
    deliveries = deliveries.where(status: @filters["status"]) if Delivery.statuses.key?(@filters["status"])
    from = parse_date(@filters["from"])
    to = parse_date(@filters["to"])
    deliveries = deliveries.where(delivered_at: from.beginning_of_day..) if from
    deliveries = deliveries.where(delivered_at: ..to.end_of_day) if to
    @today_count = policy_scope(Delivery).delivered.where(delivered_at: Time.current.all_day).count
    @pagy, @deliveries = pagy(deliveries.order(delivered_at: :desc, id: :desc))
  end

  def show
    authorize @delivery
  end

  def new
    @delivery = Delivery.new(driver: current_user.chofer? ? current_user : nil)
    authorize @delivery
    @delivery.lines.build
    load_form_options
  end

  def create
    @delivery = Delivery.new(delivery_params)
    @delivery.driver = current_user if current_user.chofer?
    @delivery.vehicle = active_vehicle_of(@delivery.driver)
    authorize @delivery

    if @delivery.register(by: current_user)
      redirect_to @delivery, notice: "Entrega registrada. Se descontó del stock."
    else
      @delivery.lines.build if @delivery.lines.empty?
      load_form_options
      render :new, status: :unprocessable_content
    end
  end

  def cancel
    authorize @delivery
    if @delivery.cancel(by: current_user, reason: params[:cancel_reason])
      redirect_to @delivery, notice: "Entrega anulada. Lo entregado volvió al stock."
    else
      redirect_to @delivery, alert: "No se pudo anular la entrega."
    end
  end

  private

  def set_delivery
    @delivery = Delivery.find(params[:id])
  end

  def delivery_params
    permitted = params.require(:delivery).permit(:customer, :address, :notes, :receipt, :driver_id,
                                                 lines_attributes: %i[product_id quantity])
    permitted.delete(:driver_id) if current_user.chofer?
    if permitted[:driver_id].present? && !company_drivers.exists?(id: permitted[:driver_id])
      permitted.delete(:driver_id)
    end
    permitted[:lines_attributes]&.each_value do |line|
      line[:product_id] = nil unless line[:product_id].blank? || company_products.exists?(id: line[:product_id])
    end
    permitted
  end

  def load_form_options
    chosen = @delivery.lines.map(&:product_id).compact
    @products = company_products.where("products.stock > 0").or(company_products.where(id: chosen)).order(:name)
    @drivers = company_drivers unless current_user.chofer?
  end

  # El chofer no ve el inventario, pero sí elige productos de su empresa al entregar.
  def company_products
    Product.unscoped.where(company_id: current_user.company_id)
  end

  def company_drivers
    User.where(company_id: current_user.company_id, role: :chofer).order(:email)
  end

  def active_vehicle_of(user)
    user&.vehicle_assignments&.active&.first&.vehicle
  end

  def parse_date(value)
    Date.iso8601(value) if value.present?
  rescue Date::Error
    nil
  end
end
