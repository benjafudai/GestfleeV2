class PushSubscriptionsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [:create] # Depending on your setup, you might need this for API-like POST requests or use form authenticity tokens in JS.

  def create
    sub = current_user.push_subscriptions.find_or_initialize_by(
      endpoint: params[:endpoint]
    )
    sub.p256dh = params.dig(:keys, :p256dh)
    sub.auth = params.dig(:keys, :auth)

    if sub.save
      render json: { status: 'subscribed' }
    else
      render json: { error: sub.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
