# Bloquea en el servidor las secciones que el superadmin desactivó para la
# empresa o el usuario. Esconder el menú no basta: se podría entrar por la URL.
module RequiresFeature
  extend ActiveSupport::Concern

  class_methods do
    def requires_feature(key, **options)
      before_action(options) { require_feature!(key) }
    end
  end

  private

  def require_feature!(key)
    return if current_user.nil? || current_user.feature?(key)

    redirect_to root_path, alert: "La sección #{Feature.name_for(key)} no está activa para tu cuenta. Contacta al equipo GestFlee para activarla."
  end
end
