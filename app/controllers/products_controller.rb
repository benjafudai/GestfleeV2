class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: %i[show edit update destroy]

  def index
    authorize Product
    scope = policy_scope(Product)
    @categories = scope.where.not(category: nil).distinct.order(:category).pluck(:category)
    @summary = { total: scope.count, low_stock: scope.low_stock.count }

    products = scope
    if params[:q].present?
      term = "%#{Product.sanitize_sql_like(params[:q].strip)}%"
      products = products.where("products.name ILIKE :term OR products.code ILIKE :term", term: term)
    end
    products = products.where(category: params[:category]) if params[:category].present?
    products = products.low_stock if params[:stock] == "bajo"
    @pagy, @products = pagy(products.order(:name))
  end

  def show
    authorize @product
    @movement = ProductMovement.new(product: @product, kind: :entry) if policy(@product).move?
    @pagy, @movements = pagy(@product.movements.includes(:user, :delivery), limit: 20)
  end

  def new
    authorize Product
    @product = Product.new
  end

  def edit
    authorize @product
  end

  # El stock inicial queda como primer movimiento (ajuste), para que el historial cuadre.
  def create
    authorize Product
    @product = Product.new(product_params)
    initial_stock = @product.stock

    if @product.valid? && save_with_initial_stock(initial_stock)
      redirect_to @product, notice: "Producto creado correctamente."
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @product
    if @product.update(product_params.except(:stock))
      redirect_to @product, notice: "Producto actualizado correctamente."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @product
    if @product.destroy
      redirect_to products_url, notice: "Producto eliminado."
    else
      redirect_to @product, alert: "No se puede eliminar: el producto aparece en entregas registradas. Déjalo con stock 0 si ya no se vende."
    end
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def save_with_initial_stock(quantity)
    Product.transaction do
      @product.stock = 0
      @product.save!
      next true if quantity.zero?

      ProductMovement.new(product: @product, kind: :adjustment, quantity: quantity, user: current_user, note: "Stock inicial").apply ||
        raise(ActiveRecord::Rollback)
    end
  end

  def product_params
    params.require(:product).permit(:name, :code, :category, :unit, :stock, :min_stock, :price, :currency, :notes)
  end
end
