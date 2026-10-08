# Tiendas externas donde buscar un repuesto. La lista vive en
# config/part_stores.yml para poder sumar o quitar tiendas sin tocar código.
class PartStore
  attr_reader :name, :url_template

  def self.all
    @all ||= Rails.application.config_for(:part_stores).fetch(:stores).map do |store|
      new(name: store.fetch(:name), url_template: store.fetch(:url))
    end
  end

  def initialize(name:, url_template:)
    @name = name
    @url_template = url_template
  end

  # %{query} va como parámetro de búsqueda; %{slug} como palabras-separadas-por-guion.
  def url_for(query)
    slug = query.to_s.downcase.split.map { |word| ERB::Util.url_encode(word) }.join("-")
    format(url_template, query: ERB::Util.url_encode(query.to_s), slug: slug)
  end
end
