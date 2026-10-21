# Página de presentación pública (raíz del sitio para quien no ha iniciado sesión).
class PagesController < ApplicationController
  def home
    # Los botones de contacto solo aparecen si están configurados en el servidor.
    @contact_email = ENV["CONTACT_EMAIL"].presence
    @contact_whatsapp = ENV["CONTACT_WHATSAPP"].to_s.gsub(/\D/, "").presence
  end
end
