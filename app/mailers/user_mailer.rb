class UserMailer < ApplicationMailer
  def otp_code(user, code)
    @user = user
    @code = code
    @valid_minutes = (User::OTP_VALID_FOR / 60).to_i

    mail(to: @user.email, subject: "Tu código de verificación GestFlee")
  end
end
