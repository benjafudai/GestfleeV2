# Password reset requests are handled only by the GestFlee team (superadmins),
# not by each company's admin.
class PasswordResetRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_superadmin!

  def index
    @pending_requests = PasswordResetRequest.includes(user: :company).where(status: :pending).order(created_at: :desc)
  end

  def show
    @password_reset_request = PasswordResetRequest.find(params[:id])
  end

  def update
    @password_reset_request = PasswordResetRequest.find(params[:id])

    user = @password_reset_request.user
    
    if user.update(password: params[:password], password_confirmation: params[:password_confirmation], force_password_change: true)
      @password_reset_request.update!(status: :completed, admin: current_user)
      redirect_to password_reset_requests_path, notice: "La contraseña del usuario #{user.email} ha sido actualizada exitosamente."
    else
      redirect_to password_reset_request_path(@password_reset_request), alert: "Error al actualizar la contraseña: #{user.errors.full_messages.to_sentence}"
    end
  end

  private

  def authorize_superadmin!
    unless current_user.superadmin?
      redirect_to root_path, alert: "No tienes permisos para acceder a esta página."
    end
  end
end
