module ProductsHelper
  # Píldora de stock de un producto: roja sin stock, amarilla bajo el mínimo, verde en otro caso.
  def product_stock_badge(product)
    amount = quantity_with_unit(product.stock, product.unit)
    if product.stock <= 0
      tag.span("Sin stock", class: "badge text-bg-danger")
    elsif product.low_stock?
      tag.span(amount, class: "badge text-bg-warning", title: "Bajo el mínimo (#{format_quantity(product.min_stock)})")
    else
      tag.span(amount, class: "badge text-bg-success")
    end
  end

  # Valor del inventario en pesos (stock por precio), contando solo productos con precio.
  def products_stock_value(scope)
    values = scope.where.not(price: nil).unscope(:order).group(:currency).sum(Arel.sql("products.stock * products.price"))
    clp = values.fetch("CLP", 0).to_d
    usd = values.fetch("USD", 0).to_d
    usd.positive? ? clp + converted_to_clp(usd, "USD").to_d : clp
  end

  # Cantidad del movimiento con su signo: "+20 kg", "-3 cajas", "= 15 kg" para un ajuste.
  def product_movement_quantity(movement, unit)
    sign = { "entry" => "+", "withdrawal" => "-", "adjustment" => "= " }[movement.kind]
    tone = { "entry" => "text-success", "withdrawal" => "text-danger", "adjustment" => "text-body" }[movement.kind]
    tag.span("#{sign}#{quantity_with_unit(movement.quantity, unit)}", class: "fw-bold #{tone}")
  end
end
