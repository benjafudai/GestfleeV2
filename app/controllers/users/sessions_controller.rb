class Users::SessionsController < Devise::SessionsController
  def create
    self.resource = warden.authenticate!(auth_options)

    if !two_factor_enabled? || device_trusted?(resource)
      finish_sign_in(resource)
    else
      challenge_with_otp(resource)
    end
  end

  private

  # Desactivado por defecto; se activa con TWO_FACTOR_ENABLED=true en el .env
  def two_factor_enabled?
    ENV["TWO_FACTOR_ENABLED"] == "true"
  end

  def device_trusted?(user)
    token = cookies.encrypted[:"otp_remember_#{user.id}"]
    user.remember_device_valid?(token)
  end

  def challenge_with_otp(user)
    code = user.generate_otp!
    UserMailer.otp_code(user, code).deliver_now

    session[:otp_pending_user_id] = user.id
    session[:otp_remember_me] = params.dig(resource_name, :remember_me)
    sign_out(user)

    redirect_to new_two_factor_path, notice: "Te enviamos un código de verificación a #{user.masked_email}."
  end

  def finish_sign_in(user)
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, user)
    respond_with resource, location: after_sign_in_path_for(user)
  end
end
