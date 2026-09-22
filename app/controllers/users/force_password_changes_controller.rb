class Users::ForcePasswordChangesController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :check_force_password_change

  def edit
    # Render the force password change form
  end

  def update
    if current_user.update(password_params.merge(force_password_change: false))
      # Sign in the user by bypassing validation in case of password changes
      bypass_sign_in(current_user)
      redirect_to root_path, notice: "Tu contraseña ha sido actualizada exitosamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
