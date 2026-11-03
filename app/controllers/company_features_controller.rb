# Panel del superadmin: qué secciones de la app usa una empresa y, dentro de
# ella, excepciones por usuario (activar o quitar una sección solo a esa
# persona). Desactivar no borra datos: solo
# esconde la sección y la bloquea por URL.
class CompanyFeaturesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_superadmin!
  before_action :set_company

  def edit
    load_form
  end

  def update
    saved = ActiveRecord::Base.transaction do
      apply_overrides(@company, params.dig(:features, :company) || {}, default_mode: "on")
      (params.dig(:features, :users) || {}).each do |user_id, features|
        apply_overrides(@company.users.find(user_id), features, default_mode: "company")
      end
      true
    rescue ActiveRecord::RecordInvalid => e
      @error = e.record.errors.full_messages.to_sentence
      raise ActiveRecord::Rollback
    end

    if saved
      redirect_to edit_company_features_path(@company), notice: "Funciones de #{@company.name} actualizadas."
    else
      load_form
      flash.now[:alert] = "No se pudo guardar: #{@error}"
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_company
    @company = Company.find(params[:company_id])
  end

  def load_form
    @users = @company.users.order(:role, :email).to_a
    @overrides = FeatureOverride.where(subject: [@company, *@users])
                                .index_by { |o| [o.subject_type, o.subject_id, o.feature] }
  end

  # Cada sección llega como "on", "off" o (solo usuarios) "company". Lo normal
  # ("on" para la empresa, "company" para un usuario) no guarda fila.
  def apply_overrides(subject, features, default_mode:)
    features.each do |key, mode|
      next unless Feature.keys.include?(key.to_s)

      override = FeatureOverride.find_or_initialize_by(subject: subject, feature: key.to_s)
      if mode.to_s == default_mode
        override.destroy! if override.persisted?
      elsif mode.to_s.in?(%w[on off])
        enabled = mode.to_s == "on"
        next if override.persisted? && override.enabled == enabled && override.expires_on.nil?

        override.update!(enabled: enabled, expires_on: nil, granted_by: current_user)
      end
    end
  end

  def ensure_superadmin!
    redirect_to root_path, alert: "No tienes permisos para acceder a esta página." unless current_user&.superadmin?
  end
end
