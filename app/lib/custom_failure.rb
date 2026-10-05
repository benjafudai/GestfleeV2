class CustomFailure < Devise::FailureApp
  SILENT_MESSAGES = [nil, :unauthenticated].freeze

  def redirect
    store_location!
    flash[:alert] = i18n_message unless SILENT_MESSAGES.include?(warden_message)
    redirect_to redirect_url
  end
end
