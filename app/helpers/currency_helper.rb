module CurrencyHelper
  def format_money(amount, currency)
    return "-" unless amount.present?

    if currency == 'USD'
      number_to_currency(amount, unit: "USD $", precision: 2)
    else
      number_to_currency(amount, unit: "CLP $", precision: 0, delimiter: ".")
    end
  end

  def converted_to_clp(amount, currency)
    return 0.0 unless amount
    if currency == 'USD'
      amount * CurrencyConverter.usd_to_clp
    else
      amount
    end
  end

  def converted_to_usd(amount, currency)
    return 0.0 unless amount
    if currency == 'CLP'
      amount / CurrencyConverter.usd_to_clp
    else
      amount
    end
  end
end
