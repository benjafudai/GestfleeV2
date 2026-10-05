class FailureAnalyticsPolicy < Struct.new(:user, :failure_analytics)
  def index?
    user.admin? || user.superadmin? || user.analista?
  end
end
