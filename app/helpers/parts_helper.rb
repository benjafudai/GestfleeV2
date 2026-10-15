module PartsHelper
  # Unidades cortas con plural propio ("unid" es abreviatura y no cambia). Las demás de 3 letras
  # o menos se tratan como abreviaturas (kg, lts, und) y quedan igual.
  UNIT_PLURALS = { "par" => "pares", "kit" => "kits", "set" => "sets", "pack" => "packs", "unid" => "unid" }.freeze

  # Título de tarjeta con su ícono en un círculo suave (repuestos, búsqueda y solicitudes).
  def inventory_card_title(title, icon:, tone: "primary", tag_name: :h5)
    circle = tag.span(tag.i(class: "bi #{icon}"),
                      class: "d-inline-flex align-items-center justify-content-center flex-shrink-0 rounded-circle " \
                             "bg-#{tone}-subtle text-#{tone}-emphasis lh-1 p-2",
                      "aria-hidden": true)
    content_tag(tag_name, safe_join([circle, title]), class: "mb-0 d-flex align-items-center gap-2")
  end

  # Unidad de medida concordada con la cantidad: "1 litro", "160 litros", "2 unidades", "3 galones".
  # Abreviaturas (kg, L, m3, lts) se muestran tal cual; en "caja de 12" se concuerda la primera palabra.
  def unit_of_measure_label(quantity, unit)
    unit = unit.to_s.strip
    return unit if unit.blank? || quantity.to_d == 1

    # "caja de 12" -> "cajas de 12"
    if (match = unit.match(/\A(\S+)( de .+)\z/))
      return "#{unit_of_measure_label(quantity, match[1])}#{match[2]}"
    end

    word = unit.downcase
    return UNIT_PLURALS[word] if UNIT_PLURALS.key?(word)
    return unit unless unit.match?(/\A[[:alpha:]]{4,}\z/) && unit != unit.upcase && word.match?(/[aeiouáéíóú]/)
    return unit if word.end_with?("s", "x")

    if word.match?(/[aeiouáéíóú]\z/)
      "#{unit}s"
    elsif word.end_with?("z")
      "#{unit[0...-1]}ces"
    else
      # Las agudas pierden la tilde al sumar sílaba: galón -> galones.
      "#{unit.sub(/([áéíóú])([^aeiouáéíóú]*)\z/) { "#{Regexp.last_match(1).tr('áéíóú', 'aeiou')}#{Regexp.last_match(2)}" }}es"
    end
  end

  # Cantidad con su unidad: "160 litros", "1,5 litros", "1 juego".
  def quantity_with_unit(quantity, unit)
    [format_quantity(quantity), unit_of_measure_label(quantity, unit)].compact_blank.join(" ")
  end

  # Valor para <input type="number">: sin ceros de relleno (160.0 -> "160", 12.50 -> "12.5")
  # y siempre con punto decimal, que es lo que entiende el navegador.
  def decimal_field_value(number)
    return if number.nil?

    number_with_precision(number, precision: 2, strip_insignificant_zeros: true, separator: ".", delimiter: "")
  end

  # Cantidad legible en formato chileno: 1250.5 -> "1.250,5"
  def format_quantity(number)
    number_with_precision(number || 0, precision: 2, strip_insignificant_zeros: true, separator: ",", delimiter: ".")
  end

  # Píldora de stock: verde con existencias, roja cuando no queda nada.
  # Con unit: "Stock 160 litros".
  def part_stock_badge(stock, prefix: nil, unit: nil)
    if stock.to_d.positive?
      amount = unit ? quantity_with_unit(stock, unit) : format_quantity(stock)
      tag.span([prefix, amount].compact.join(" "), class: "badge text-bg-success")
    else
      tag.span("Sin stock", class: "badge text-bg-danger")
    end
  end

  # Costo en su moneda y, si está en dólares, su equivalente aproximado en pesos.
  def part_cost_with_clp(amount, currency)
    main = tag.span(format_money(amount, currency))
    return main unless currency == "USD"

    safe_join([main, tag.div("≈ #{format_money(converted_to_clp(amount, 'USD'), 'CLP')}", class: "small text-muted")])
  end

  # Resumen del catálogo para las tarjetas del listado.
  def parts_summary(scope)
    values = scope.unscope(:order).group(:currency).sum(Arel.sql("parts.stock * parts.cost"))
    clp = values.fetch("CLP", 0).to_d
    usd = values.fetch("USD", 0).to_d
    clp += converted_to_clp(usd, "USD").to_d if usd.positive?

    {
      total: scope.count,
      out_of_stock: scope.where("parts.stock <= 0").count,
      stock_value: clp
    }
  end
end
