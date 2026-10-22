require "prawn"
require "prawn/table"

# PDF del resumen semanal de una empresa (ver WeeklySummary).
# Usa las fuentes incluidas en Prawn (Helvetica), que cubren el español; el texto que
# viene de los datos se limpia de caracteres que esas fuentes no pueden dibujar.
class WeeklySummaryPdf
  NAVY = "0E2240".freeze
  PRIMARY = "1F6FD1".freeze
  ORANGE = "F97316".freeze
  TEXT = "1D2A3B".freeze
  MUTED = "5F6E83".freeze
  LINE = "E2E7EE".freeze
  SOFT = "F2F5F9".freeze
  DANGER = "D64545".freeze
  WARNING = "B07A10".freeze

  Prawn::Fonts::AFM.hide_m17n_warning = true

  def initialize(summary, generated_at: Time.current)
    @summary = summary
    @data = summary.to_h
    @generated_at = generated_at
  end

  def render
    pdf = Prawn::Document.new(page_size: "A4", margin: [36, 36, 48, 36], info: {
      Title: "Resumen semanal - #{clean(@summary.company.name)}", Creator: "GestFlee"
    })
    @pdf = pdf
    pdf.font "Helvetica"
    pdf.default_leading 2
    pdf.fill_color TEXT

    header
    kpis
    documents_section
    work_orders_section
    fuel_and_expenses_section
    incidents_and_checklists_section
    inventory_section
    footer
    pdf.render
  end

  def filename
    "resumen-semanal-#{@summary.company.name.to_s.parameterize.presence || 'empresa'}-#{@summary.week_end.iso8601}.pdf"
  end

  private

  attr_reader :pdf

  def header
    top = pdf.bounds.top
    pdf.fill_color NAVY
    pdf.fill_rounded_rectangle [0, top], pdf.bounds.width, 78, 10
    pdf.fill_color ORANGE
    pdf.fill_rounded_rectangle [18, top - 18], 26, 26, 6
    pdf.fill_color "FFFFFF"
    pdf.text_box "G", at: [18, top - 23], width: 26, align: :center, size: 15, style: :bold
    pdf.text_box "GestFlee", at: [52, top - 20], size: 15, style: :bold
    pdf.fill_color "A9BFDC"
    pdf.text_box "Resumen semanal", at: [52, top - 38], size: 9
    pdf.fill_color "FFFFFF"
    pdf.text_box clean(@summary.company.name), at: [200, top - 18], width: pdf.bounds.width - 218,
                 align: :right, size: 14, style: :bold, overflow: :shrink_to_fit, height: 20
    pdf.fill_color "C3D0E3"
    pdf.text_box @summary.period_label, at: [200, top - 42], width: pdf.bounds.width - 218, align: :right, size: 10
    pdf.fill_color TEXT
    pdf.move_down 96
  end

  def kpis
    docs = @data[:documents]
    orders = @data[:work_orders]
    boxes = [
      ["Gasto de la semana", money(@data[:expenses][:total_clp]), "todas las categorías"],
      ["Combustible", "#{number(@data[:fuel][:liters])} L", "#{@data[:fuel][:fills]} #{plural(@data[:fuel][:fills], 'carga', 'cargas')}"],
      ["Órdenes abiertas", orders[:open_count].to_s, "#{orders[:completed]} #{plural(orders[:completed], 'completada', 'completadas')} en la semana"],
      ["Documentos", "#{docs[:expired]} #{plural(docs[:expired], 'vencido', 'vencidos')}", "#{docs[:expiring]} por vencer en 30 días"]
    ]
    gap = 10
    width = (pdf.bounds.width - gap * 3) / 4
    top = pdf.cursor
    boxes.each_with_index do |(label, value, note), index|
      x = index * (width + gap)
      pdf.fill_color SOFT
      pdf.fill_rounded_rectangle [x, top], width, 62, 8
      pdf.fill_color MUTED
      pdf.text_box label.upcase, at: [x + 10, top - 10], width: width - 20, size: 7, style: :bold
      pdf.fill_color(index == 3 && docs[:expired].positive? ? DANGER : TEXT)
      pdf.text_box value, at: [x + 10, top - 24], width: width - 20, size: 15, style: :bold, overflow: :shrink_to_fit, height: 18
      pdf.fill_color MUTED
      pdf.text_box note, at: [x + 10, top - 45], width: width - 20, size: 7.5, overflow: :shrink_to_fit, height: 12
    end
    pdf.fill_color TEXT
    pdf.move_down 80
  end

  def documents_section
    docs = @data[:documents]
    section_title "Documentos vencidos y por vencer"
    if docs[:rows].empty?
      note "No hay documentos vencidos ni por vencer en los próximos 30 días."
      return
    end

    rows = docs[:rows].map do |row|
      status = row[:expired] ? "Vencido" : "Por vencer"
      [clean(row[:owner]), clean(row[:type]), I18n.l(row[:due_on]), status]
    end
    data_table(["Vehículo o persona", "Documento", "Vence", "Estado"], rows, widths: [nil, nil, 70, 70]) do |table|
      table.column(3).rows(1..-1).each do |cell|
        cell.text_color = cell.content == "Vencido" ? DANGER : WARNING
        cell.font_style = :bold
      end
    end
    note "Y #{docs[:more]} más. Revísalos en Alertas." if docs[:more].positive?
  end

  def work_orders_section
    orders = @data[:work_orders]
    section_title "Órdenes de trabajo"
    note "Creadas en la semana: #{orders[:created]}   Completadas: #{orders[:completed]}   Abiertas al cierre: #{orders[:open_count]}"
    return if orders[:open].empty?

    rows = orders[:open].map do |order|
      [clean(order[:plate]), order[:status], I18n.l(order[:since]), clean(order[:notes]).presence || "-"]
    end
    data_table(["Vehículo", "Estado", "Desde", "Notas"], rows, widths: [70, 75, 65, nil])
  end

  def fuel_and_expenses_section
    fuel = @data[:fuel]
    expenses = @data[:expenses]
    section_title "Combustible y gastos"
    efficiency = fuel[:km_per_liter] ? "#{number(fuel[:km_per_liter], 2)} km/L" : "sin datos"
    note "Combustible: #{fuel[:fills]} #{plural(fuel[:fills], 'carga', 'cargas')}, #{number(fuel[:liters])} L, " \
         "#{money(fuel[:cost_clp])}. Rendimiento promedio: #{efficiency}."
    if expenses[:by_category].empty?
      note "No se registraron gastos en la semana."
      return
    end

    rows = expenses[:by_category].map do |category, amount|
      [ApplicationHelper::EXPENSE_CATEGORY_LABELS[category] || category.to_s.humanize, money(amount)]
    end
    rows << ["Total", money(expenses[:total_clp])]
    data_table(["Categoría", "Monto (CLP)"], rows, widths: [nil, 120]) do |table|
      table.column(1).align = :right
      table.row(-1).font_style = :bold
      table.row(-1).background_color = SOFT
    end
    note "Los gastos en dólares se convierten a pesos con la tasa del día." if expenses[:by_category].any?
  end

  def incidents_and_checklists_section
    incidents = @data[:incidents]
    checklists = @data[:checklists]
    section_title "Incidentes y checklists"
    severities = incidents[:by_severity].sort_by { |severity, _| -Incident.severities.fetch(severity, -1) }.map do |severity, count|
      "#{count} #{(ApplicationHelper::INCIDENT_SEVERITY_LABELS[severity] || 'sin gravedad').downcase}"
    end
    detail = severities.any? ? " (#{severities.join(', ')})" : ""
    note "Incidentes reportados en la semana: #{incidents[:reported]}#{detail}. Sin resolver al cierre: #{incidents[:open]}."
    note "Checklists enviados: #{checklists[:total]}. Aprobados: #{checklists[:approved]}, " \
         "rechazados: #{checklists[:rejected]}, por revisar: #{checklists[:pending]}."
  end

  def inventory_section
    parts = @data[:low_stock_parts]
    section_title "Inventario"
    note "Solicitudes de suministro sin entregar: #{@data[:pending_supply_requests]}."
    if parts.empty?
      note "No hay repuestos con stock bajo (#{WeeklySummary::LOW_STOCK} o menos)."
      return
    end

    rows = parts.map { |part| [clean(part[:name]), clean(part[:sku]), "#{number(part[:stock])} #{clean(part[:unit])}"] }
    data_table(["Repuesto con stock bajo", "Código", "Stock"], rows, widths: [nil, 110, 80]) do |table|
      table.column(2).align = :right
    end
  end

  def footer
    stamp = "Generado por GestFlee el #{I18n.l(@generated_at.to_date)} - gestflee.cl"
    pdf.repeat(:all) do
      pdf.bounding_box([0, pdf.bounds.bottom - 14], width: pdf.bounds.width, height: 20) do
        pdf.fill_color MUTED
        pdf.text stamp, size: 7.5
      end
    end
    pdf.number_pages "Página <page> de <total>", at: [pdf.bounds.right - 120, pdf.bounds.bottom - 14],
                     width: 120, align: :right, size: 7.5, color: MUTED
  end

  def section_title(title)
    pdf.start_new_page if pdf.cursor < 90
    pdf.move_down 10
    pdf.fill_color PRIMARY
    pdf.fill_rectangle [0, pdf.cursor + 1], 3, 13
    pdf.fill_color NAVY
    pdf.indent(10) { pdf.text title, size: 12, style: :bold }
    pdf.fill_color TEXT
    pdf.move_down 6
  end

  def note(text)
    pdf.fill_color TEXT
    pdf.text clean(text), size: 9.5
    pdf.move_down 6
  end

  def data_table(header, rows, widths:)
    total = pdf.bounds.width
    fixed = widths.compact.sum
    flexible = widths.count(&:nil?)
    column_widths = widths.map { |width| width || (total - fixed) / flexible }
    pdf.table([header] + rows, header: true, width: total, column_widths: column_widths,
              cell_style: { size: 8.5, padding: [4, 6], border_color: LINE, border_width: 0.5, text_color: TEXT }) do |table|
      table.row(0).font_style = :bold
      table.row(0).background_color = SOFT
      table.row(0).text_color = MUTED
      yield table if block_given?
    end
    pdf.move_down 8
  end

  def money(amount)
    ActiveSupport::NumberHelper.number_to_currency(amount.to_f.round, unit: "$", precision: 0, delimiter: ".", format: "%u%n")
  end

  def number(value, precision = 1)
    rounded = value.to_f.round(precision)
    rounded = rounded.to_i if rounded == rounded.to_i
    ActiveSupport::NumberHelper.number_to_delimited(rounded, delimiter: ".", separator: ",")
  end

  def plural(count, one, many)
    count == 1 ? one : many
  end

  # Helvetica solo dibuja Windows-1252: lo demás (emojis, otros alfabetos) se cambia por "?".
  def clean(text)
    text.to_s.encode("Windows-1252", invalid: :replace, undef: :replace, replace: "?").encode("UTF-8")
  end
end
