# RUT chileno: valida el dígito verificador y lo deja escrito como 12.345.678-5.
module Rut
  module_function

  def clean(value)
    value.to_s.upcase.gsub(/[^0-9K]/, "")
  end

  def valid?(value)
    digits = clean(value)
    return false unless digits.match?(/\A\d{7,8}[0-9K]\z/)

    digits[-1] == check_digit(digits[0..-2])
  end

  def format(value)
    digits = clean(value)
    return value unless valid?(digits)

    "#{digits[0..-2].reverse.scan(/\d{1,3}/).join('.').reverse}-#{digits[-1]}"
  end

  def check_digit(number)
    sum = number.reverse.chars.each_with_index.sum { |digit, index| digit.to_i * ((index % 6) + 2) }
    { 11 => "0", 10 => "K" }.fetch(11 - (sum % 11)) { (11 - (sum % 11)).to_s }
  end
end
