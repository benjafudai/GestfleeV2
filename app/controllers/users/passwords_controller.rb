class Users::PasswordsController < Devise::PasswordsController
  def create
    self.resource = resource_class.find_by(email: resource_params[:email])

    if resource
      # Create the password reset request
      reset_request = resource.password_reset_requests.create!(status: :pending)

      # Notify admins of the user's company
      if resource.company.present?
        admins = resource.company.users.where(role: [:admin, :superadmin])
        admins.each do |admin|
          Notification.create!(
            user: admin,
            notifiable: reset_request,
            title: "Solicitud de Recuperación de Contraseña",
            message: "El usuario #{resource.email} ha solicitado recuperar su contraseña."
          )
        end
      end

      redirect_to new_user_session_path, notice: "Tu administrador ha sido notificado para restablecer tu contraseña. Recibirás indicaciones pronto."
    else
      # Behave standard if not found to show the error
      set_flash_message(:alert, :not_found, scope: 'devise.passwords')
      redirect_to new_user_password_path
    end
  end
end
