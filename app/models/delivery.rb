# Entrega de productos a un cliente, registrada por el chofer. Al registrarla se
# descuenta el stock de cada producto; al anularla, el stock se devuelve.
class Delivery < ApplicationRecord
  include CompanyScoped

  MAX_LINES = 30
  RECEIPT_MAX_SIZE = 10.megabytes
  RECEIPT_TYPES = %w[image/jpeg image/png image/webp image/heic image/heif application/pdf].freeze
  PHOTO_TYPES = RECEIPT_TYPES - %w[application/pdf]
  RECIPIENT_RELATIONS = [ "Cliente", "Familiar", "Trabajador o encargado", "Conserje o portería", "Vecino", "Otro" ].freeze

  belongs_to :driver, class_name: "User", optional: true
  belongs_to :vehicle, optional: true
  belongs_to :cancelled_by, class_name: "User", optional: true
  has_many :lines, class_name: "DeliveryLine", dependent: :delete_all, inverse_of: :delivery
  has_many :product_movements, dependent: :nullify
  has_one_attached :receipt
  # Foto de la entrega, como la que pide Mercado Libre: el producto entregado o quien lo recibe.
  has_one_attached :photo

  enum :status, { delivered: 0, cancelled: 1 }

  accepts_nested_attributes_for :lines, reject_if: ->(attrs) { attrs[:product_id].blank? && attrs[:quantity].blank? }

  normalizes :customer, :address, :recipient_name, :recipient_relation, with: ->(value) { value.strip.presence }
  normalizes :recipient_rut, with: ->(value) { Rut.format(value.strip).presence }

  validates :customer, presence: true, length: { maximum: 120 }
  validates :address, length: { maximum: 200 }
  validates :notes, length: { maximum: 1000 }
  validates :cancel_reason, length: { maximum: 255 }
  # Las entregas anteriores al comprobante no lo tienen; se exige solo al registrar una nueva.
  validates :recipient_name, presence: true, on: :create
  validates :recipient_name, length: { maximum: 120 }
  validates :recipient_relation, inclusion: { in: RECIPIENT_RELATIONS }, allow_nil: true
  validate :recipient_rut_is_valid
  validate :photo_is_valid
  validate :has_lines
  validate :products_not_repeated
  validate :receipt_is_valid

  # Guarda la entrega y descuenta el stock. Si algún producto no alcanza, no guarda
  # nada y deja el error en la entrega.
  def register(by:)
    self.delivered_at ||= Time.current
    return false unless valid?

    transaction do
      save!
      lines.each do |line|
        movement = ProductMovement.new(product: line.product, kind: :withdrawal, quantity: line.quantity,
                                       user: by, delivery: self, note: "Entrega a #{customer}")
        next if movement.apply

        product = line.product.reload
        errors.add(:base, "No hay stock suficiente de #{product.name}: se entregan #{quantity_text(line.quantity, product)} " \
                          "y el sistema tiene #{quantity_text(product.stock, product)}. Avisa a bodega para que corrija el stock.")
        raise ActiveRecord::Rollback
      end
    end
    errors.empty? && persisted?
  end

  # Anula la entrega y devuelve al stock lo entregado.
  def cancel(by:, reason: nil)
    return false unless delivered?

    transaction do
      lines.each do |line|
        ProductMovement.new(product: line.product, kind: :entry, quantity: line.quantity, user: by,
                            delivery: self, note: "Entrega anulada: #{customer}").apply || raise(ActiveRecord::Rollback)
      end
      update!(status: :cancelled, cancelled_at: Time.current, cancelled_by: by, cancel_reason: reason.to_s.strip.presence)
    end
    cancelled?
  end

  private

  def quantity_text(value, product)
    ApplicationController.helpers.quantity_with_unit(value, product.unit)
  end

  def has_lines
    kept = lines.reject(&:marked_for_destruction?)
    errors.add(:base, "Agrega al menos un producto entregado") if kept.empty?
    errors.add(:base, "Una entrega admite hasta #{MAX_LINES} productos") if kept.size > MAX_LINES
  end

  def products_not_repeated
    repeated = lines.map(&:product).compact.tally.select { |_, count| count > 1 }.keys
    errors.add(:base, "Hay productos repetidos: #{repeated.map(&:name).join(', ')}. Suma las cantidades en una sola línea") if repeated.any?
  end

  def recipient_rut_is_valid
    errors.add(:recipient_rut, "no es válido. Revisa el número y el dígito verificador") if recipient_rut && !Rut.valid?(recipient_rut)
  end

  def photo_is_valid
    if !photo.attached?
      errors.add(:photo, "es obligatoria. Saca una foto de lo entregado o de quien recibe") if new_record?
      return
    end

    errors.add(:photo, "debe ser una imagen") unless PHOTO_TYPES.include?(photo.content_type)
    errors.add(:photo, "no puede pesar más de 10 MB") if photo.byte_size > RECEIPT_MAX_SIZE
  end

  def receipt_is_valid
    return unless receipt.attached?

    errors.add(:receipt, "debe ser una foto o un PDF") unless RECEIPT_TYPES.include?(receipt.content_type)
    errors.add(:receipt, "no puede pesar más de 10 MB") if receipt.byte_size > RECEIPT_MAX_SIZE
  end
end
