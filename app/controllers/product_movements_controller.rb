class ProductMovementsController < ApplicationController
  before_action :authenticate_user!

  def create
    @product = Product.find(params[:product_id])
    authorize @product, :move?
    @movement = ProductMovement.new(movement_params.merge(product: @product, user: current_user))

    if @movement.apply
      redirect_to @product, notice: "#{@movement.adjustment? ? 'Ajuste registrado' : "#{@movement.kind_label} registrada"}. " \
                                    "Stock actual: #{helpers.quantity_with_unit(@product.stock, @product.unit)}."
    else
      @pagy, @movements = pagy(@product.movements.includes(:user, :delivery), limit: 20)
      render "products/show", status: :unprocessable_content
    end
  end

  private

  def movement_params
    params.require(:product_movement).permit(:kind, :quantity, :note)
  end
end
