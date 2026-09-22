class AlertPolicy < Struct.new(:user, :alert)
  def index?
    user.admin? || user.superadmin? || user.analista?
  end
end
