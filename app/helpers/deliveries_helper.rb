module DeliveriesHelper
  # Productos de una entrega en una línea: "10 kg Lomo vetado, 2 cajas Hamburguesas".
  def delivery_lines_summary(delivery)
    delivery.lines.map { |line| "#{quantity_with_unit(line.quantity, line.product.unit)} #{line.product.name}" }.join(", ")
  end

  def delivery_status_badge(delivery)
    if delivery.cancelled?
      tag.span("Anulada", class: "badge text-bg-secondary")
    else
      tag.span("Entregada", class: "badge text-bg-success")
    end
  end

  # Opción del selector de productos: nombre y lo que queda, con la unidad para el campo de cantidad.
  def delivery_product_options(products, selected)
    options = products.map do |product|
      [ "#{product.name} (quedan #{quantity_with_unit(product.stock, product.unit)})", product.id, { data: { unit: product.unit } } ]
    end
    options_for_select(options, selected)
  end
end
