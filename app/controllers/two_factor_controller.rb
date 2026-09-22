class TwoFactorController < ApplicationController
  before_action :set_pending_user
  before_action :ensure_pending_user

  def new
  end

  def create
    if @pending_user.otp_expired?
      flash.now[:alert] = "El código expiró. Solicita uno nuevo."
      render :new, status: :unprocessable_entity
    elsif @pending_user.otp_locked_out?
      session.delete(:otp_pending_user_id)
      redirect_to new_user_session_path, alert: "Demasiados intentos fallidos. Ingresa nuevamente con tu contraseña."
    elsif @pending_user.verify_otp(params[:code].to_s.strip)
      complete_sign_in
    else
      flash.now[:alert] = "Código incorrecto. Verifica e intenta de nuevo."
      render :new, status: :unprocessable_entity
    end
  end

  def resend
    if @pending_user.otp_sent_recently?
      redirect_to new_two_factor_path, alert: "Espera unos segundos antes de pedir un nuevo código."
    else
      code = @pending_user.generate_otp!
      UserMailer.otp_code(@pending_user, code).deliver_now
      redirect_to new_two_factor_path, notice: "Te enviamos un nuevo código a #{@pending_user.masked_email}."
    end
  end

  private

  def set_pending_user
    @pending_user = User.find_by(id: session[:otp_pending_user_id])
  end

  def ensure_pending_user
    if @pending_user.nil?
      redirect_to new_user_session_path, alert: "Tu sesión de verificación expiró. Ingresa nuevamente."
    end
  end

  def complete_sign_in
    session.delete(:otp_pending_user_id)
    @pending_user.remember_me = true if session.delete(:otp_remember_me) == "1"
    remember_device(@pending_user) if params[:remember_device] == "1"

    sign_in(:user, @pending_user)
    redirect_to after_sign_in_path_for(@pending_user), notice: "¡Bienvenido/a de nuevo!"
  end

  def remember_device(user)
    token = user.generate_remember_device_token!
    cookies.encrypted[:"otp_remember_#{user.id}"] = {
      value: token,
      expires: User::OTP_REMEMBER_DEVICE_FOR.from_now,
      httponly: true,
      same_site: :lax
    }
  end
end
