# Datos del resumen semanal de una empresa: lo que pasó en la semana (lunes a domingo)
# y lo que queda pendiente al cierre. Lo usan el PDF (WeeklySummaryPdf) y el correo.
class WeeklySummary
  DOCUMENT_WARNING_DAYS = 30
  LOW_STOCK = 5
  LIST_LIMIT = 15

  attr_reader :company, :period

  # Por defecto, la semana pasada completa (el envío corre los lunes).
  def self.last_week(company, today: Date.current)
    week_end = today.beginning_of_week - 1
    new(company, period: (week_end - 6)..week_end)
  end

  def initialize(company, period:)
    @company = company
    @period = period
  end

  def week_start
    period.begin
  end

  def week_end
    period.end
  end

  # "Semana del 13 al 19 de octubre de 2026" o "del 29 de septiembre al 5 de octubre de 2026".
  def period_label
    if week_start.month == week_end.month
      "Semana del #{week_start.day} al #{I18n.l(week_end, format: :long)}"
    elsif week_start.year == week_end.year
      "Semana del #{I18n.l(week_start, format: '%-d de %B')} al #{I18n.l(week_end, format: :long)}"
    else
      "Semana del #{I18n.l(week_start, format: :long)} al #{I18n.l(week_end, format: :long)}"
    end
  end

  def times
    week_start.beginning_of_day..week_end.end_of_day
  end

  # Todo se calcula con la empresa fija, para que las consultas con alcance por empresa
  # den lo mismo desde una visita o desde la tarea programada.
  def to_h
    @to_h ||= Current.set(company: company, user: nil) do
      {
        documents: documents,
        work_orders: work_orders,
        fuel: fuel,
        expenses: expenses,
        incidents: incidents,
        checklists: checklists,
        low_stock_parts: low_stock_parts,
        low_stock_products: low_stock_products,
        deliveries: deliveries,
        pending_supply_requests: SupplyRequest.where(company: company).where.not(status: :delivered).count
      }
    end
  end

  private

  # Vencidos y por vencer (dentro de 30 días desde el cierre de la semana), de vehículos y personas.
  def documents
    limit_date = week_end + DOCUMENT_WARNING_DAYS
    vehicle_docs = VehicleDocument.joins(:vehicle).where(vehicles: { company_id: company.id })
                                  .where(due_on: ..limit_date).includes(:vehicle).order(:due_on)
    user_docs = UserDocument.joins(:user).where(users: { company_id: company.id })
                            .where(due_on: ..limit_date).includes(:user).order(:due_on)

    rows = vehicle_docs.map do |doc|
      { owner: doc.vehicle.plate, type: ApplicationHelper::VEHICLE_DOC_TYPE_LABELS[doc.doc_type.to_s] || doc.doc_type.to_s,
        due_on: doc.due_on, expired: doc.due_on <= week_end }
    end
    rows += user_docs.map do |doc|
      { owner: doc.user.email, type: ApplicationHelper::USER_DOC_TYPE_LABELS[doc.doc_type.to_s] || doc.doc_type.to_s,
        due_on: doc.due_on, expired: doc.due_on <= week_end }
    end
    rows.sort_by! { |row| row[:due_on] }

    { expired: rows.count { |row| row[:expired] }, expiring: rows.count { |row| !row[:expired] }, rows: rows.first(LIST_LIMIT),
      more: [rows.size - LIST_LIMIT, 0].max }
  end

  def work_orders
    scope = WorkOrder.where(company: company)
    open = scope.where(status: %i[pending in_progress]).includes(:vehicle).order(:created_at)
    {
      created: scope.where(created_at: times).count,
      completed: scope.where(status: :completed).where(updated_at: times).count,
      open_count: open.count,
      open: open.limit(LIST_LIMIT).map do |order|
        { plate: order.vehicle.plate, status: ApplicationHelper::WORK_ORDER_STATUS_LABELS[order.status],
          since: order.created_at.to_date, notes: order.notes.to_s.squish.truncate(70) }
      end
    }
  end

  def fuel
    fills = FuelFill.where(company: company, date: period)
    cost = fills.group(:currency).sum(:cost).sum { |currency, amount| to_clp(amount, currency) }
    { fills: fills.count, liters: fills.sum(:liters).to_f, cost_clp: cost,
      km_per_liter: fills.where.not(km_per_liter: nil).average(:km_per_liter)&.to_f }
  end

  def expenses
    by_category = Hash.new(0.0)
    Expense.where(company: company, date: period).group(:category, :currency).sum(:amount).each do |(category, currency), amount|
      by_category[category.to_s] += to_clp(amount, currency)
    end
    { total_clp: by_category.values.sum, by_category: by_category.sort_by { |_, amount| -amount }.to_h }
  end

  def incidents
    scope = Incident.where(company: company)
    reported = scope.where(created_at: times)
    { reported: reported.count, by_severity: reported.group(:severity).count.transform_keys(&:to_s),
      open: scope.where(status: [nil, "pending", "in_review"]).count }
  end

  def checklists
    counts = ChecklistSubmission.where(company: company, created_at: times).group(:status).count.transform_keys(&:to_s)
    { total: counts.values.sum, approved: counts["approved"].to_i, rejected: counts["rejected"].to_i, pending: counts["pending"].to_i }
  end

  def low_stock_parts
    Part.where(company: company).where(stock: ..LOW_STOCK).order(:stock, :name).limit(LIST_LIMIT)
        .map { |part| { name: part.name, sku: part.sku, stock: part.stock.to_f, unit: part.unit_of_measure } }
  end

  # Productos que vende la empresa con stock igual o menor a su mínimo.
  def low_stock_products
    Product.where(company: company).low_stock.order(:name).limit(LIST_LIMIT)
           .map { |product| { name: product.name, code: product.code, stock: product.stock.to_f, min_stock: product.min_stock.to_f, unit: product.unit } }
  end

  # Entregas de productos de la semana y lo entregado por producto (sin las anuladas).
  def deliveries
    week = Delivery.where(company: company, delivered_at: times)
    by_product = DeliveryLine.joins(:delivery, :product).merge(week.delivered).group("products.name", "products.unit")
                             .order(Arel.sql("SUM(delivery_lines.quantity) DESC")).limit(LIST_LIMIT).sum(:quantity)
    { delivered: week.delivered.count, cancelled: week.cancelled.count,
      by_product: by_product.map { |(name, unit), quantity| { name: name, unit: unit, quantity: quantity.to_f } } }
  end

  def to_clp(amount, currency)
    currency.to_s == "USD" ? amount.to_f * usd_rate : amount.to_f
  end

  def usd_rate
    @usd_rate ||= CurrencyConverter.usd_to_clp
  end
end
