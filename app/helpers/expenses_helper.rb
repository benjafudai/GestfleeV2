module ExpensesHelper
  SPANISH_MONTHS = %w[
    enero febrero marzo abril mayo junio
    julio agosto septiembre octubre noviembre diciembre
  ].freeze

  # date.strftime("%B") depende del locale del sistema operativo y en este
  # proyecto no hay config/locales/es.yml, así que devuelve el mes en inglés.
  def long_spanish_date(date)
    return "" unless date
    "#{date.day} de #{SPANISH_MONTHS[date.month - 1]}, #{date.year}"
  end
end
