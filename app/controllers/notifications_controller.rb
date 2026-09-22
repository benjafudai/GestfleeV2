class NotificationsController < ApplicationController
  def index
    @notifications = current_user.notifications.order(created_at: :desc)
    authorize @notifications
  end

  def mark_as_read
    @notification = current_user.notifications.find(params[:id])
    authorize @notification
    @notification.mark_as_read!
    redirect_back(fallback_location: notifications_path, notice: "Notificación marcada como leída.")
  end

  def mark_all_as_read
    @notifications = current_user.notifications.unread
    authorize @notifications
    @notifications.update_all(read_at: Time.current)
    redirect_back(fallback_location: notifications_path, notice: "Todas las notificaciones marcadas como leídas.")
  end
end
