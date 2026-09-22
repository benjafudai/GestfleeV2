require 'net/http'
require 'json'

class CurrencyConverter
  def self.usd_to_clp
    Rails.cache.fetch('usd_to_clp_rate', expires_in: 12.hours) do
      uri = URI('https://mindicador.cl/api/dolar')
      response = Net::HTTP.get(uri)
      json = JSON.parse(response)
      
      if json['serie'] && json['serie'].any? && json['serie'].first['valor']
        json['serie'].first['valor'].to_f
      else
        raise "Formato inesperado del API"
      end
    rescue StandardError => e
      Rails.logger.error("No se pudo obtener el valor del dólar desde mindicador.cl: #{e.message}")
      # Valor default fallback en caso de que la api no responda
      950.0 
    end
  end
end
