class ApplicationController < ActionController::Base
    include Pundit::Authorization

    # Para PaperTrail: registra quién hizo cada cambio
    before_action :set_paper_trail_whodunnit
    before_action :set_current_tenant, if: :user_signed_in?

    before_action :check_force_password_change

    private

    def check_force_password_change
      if user_signed_in? && current_user.force_password_change? && !devise_controller?
        redirect_to edit_user_force_password_change_path(current_user), alert: "Debes actualizar tu contraseña antes de continuar."
      end
    end

    def set_current_tenant
      Current.user = current_user
      Current.company = current_user.company
    rescue
       # Manejar caso superadmin global si algo falla o simplemente permitir nil
       Current.company = nil
    end

    # Manejo centralizado de errores de autorización
    rescue_from Pundit::NotAuthorizedError do
        redirect_to root_path, alert: "No autorizado."
    end

    # Un ID inválido o de otra empresa no debe mostrar la página de error de Rails
    rescue_from ActiveRecord::RecordNotFound do
        redirect_to root_path, alert: "El recurso solicitado no existe o no tienes acceso a él."
    end

    # Un valor inválido para un campo tipo enum (ej. rol, estado) lanza ArgumentError
    # al asignarlo, antes de que corra ninguna validación del modelo.
    rescue_from ArgumentError do |exception|
        redirect_back fallback_location: root_path, alert: "Datos inválidos: #{exception.message}"
    end

end
