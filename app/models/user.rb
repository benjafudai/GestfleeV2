require "digest"

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  OTP_LENGTH = 6
  OTP_VALID_FOR = 10.minutes
  OTP_RESEND_COOLDOWN = 30.seconds
  OTP_MAX_ATTEMPTS = 5
  OTP_REMEMBER_DEVICE_FOR = 30.days

  belongs_to :company, optional: true
  validates :company, presence: true, unless: :superadmin?

  enum role: {
    admin: 0,
    chofer: 1,
    mecanico: 2,
    analista: 3,
    superadmin: 4
  }
  
  validates :role, presence: true

  has_paper_trail
  has_many :vehicle_assignments, foreign_key: :user_id, dependent: :destroy
  has_one  :active_assignment, -> { VehicleAssignment.active }, class_name: 'VehicleAssignment', foreign_key: :user_id
  has_many :reported_incidents, class_name: 'Incident', foreign_key: 'reporter_id', dependent: :destroy
  has_many :checklist_submissions, dependent: :destroy
  has_many :user_documents, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy
  has_many :roadside_assistance_events, dependent: :destroy
  has_many :password_reset_requests, dependent: :destroy
  has_many :resolved_password_reset_requests, class_name: 'PasswordResetRequest', foreign_key: :admin_id, dependent: :nullify
  has_many :fuel_fills, dependent: :destroy
  has_many :supply_requests, dependent: :destroy
  has_many :work_orders, foreign_key: :mechanic_id, dependent: :nullify, inverse_of: :mechanic

  # ── Verificación en dos pasos por correo (código de un solo uso) ──

  def generate_otp!
    code = SecureRandom.random_number(10**OTP_LENGTH).to_s.rjust(OTP_LENGTH, "0")
    update_columns(otp_code_digest: otp_digest(code), otp_sent_at: Time.current, otp_attempts: 0)
    code
  end

  def verify_otp(code)
    return false if otp_code_digest.blank? || otp_expired? || otp_locked_out?

    if ActiveSupport::SecurityUtils.secure_compare(otp_code_digest, otp_digest(code.to_s))
      clear_otp!
      true
    else
      update_column(:otp_attempts, otp_attempts.to_i + 1)
      false
    end
  end

  def otp_expired?
    otp_sent_at.nil? || otp_sent_at < OTP_VALID_FOR.ago
  end

  def otp_locked_out?
    otp_attempts.to_i >= OTP_MAX_ATTEMPTS
  end

  def otp_sent_recently?
    otp_sent_at.present? && otp_sent_at > OTP_RESEND_COOLDOWN.ago
  end

  def clear_otp!
    update_columns(otp_code_digest: nil, otp_sent_at: nil, otp_attempts: 0)
  end

  # ── "Confiar en este dispositivo" — evita pedir el código de nuevo ──

  def generate_remember_device_token!
    token = SecureRandom.hex(32)
    update_columns(otp_remember_digest: otp_digest(token), otp_remember_expires_at: OTP_REMEMBER_DEVICE_FOR.from_now)
    token
  end

  def remember_device_valid?(token)
    return false if token.blank? || otp_remember_digest.blank?
    return false if otp_remember_expires_at.nil? || otp_remember_expires_at < Time.current

    ActiveSupport::SecurityUtils.secure_compare(otp_remember_digest, otp_digest(token))
  end

  def masked_email
    name, domain = email.to_s.split("@")
    return email.to_s if name.blank? || domain.blank?

    visible = name[0, 2]
    "#{visible}#{'*' * [name.length - visible.length, 3].max}@#{domain}"
  end

  private

  def otp_digest(value)
    Digest::SHA256.hexdigest(value.to_s)
  end
end
