module UsersHelper
  ROLE_LABELS = {
    'admin'      => 'Administrador',
    'chofer'     => 'Chofer',
    'mecanico'   => 'Mecánico',
    'analista'   => 'Analista',
    'superadmin' => 'Super Administrador',
    'bodeguero'  => 'Bodeguero'
  }.freeze

  def role_label(role)
    ROLE_LABELS[role.to_s] || role.to_s.humanize
  end

  # When a locked account unlocks on its own (Devise :time unlock strategy).
  def auto_unlock_time(user)
    (user.locked_at + User.unlock_in).strftime("%d/%m/%Y %H:%M")
  end

  def account_locked_badge(user)
    return unless user.access_locked?

    tag.span("Bloqueada", class: "badge text-bg-danger",
             title: "Bloqueada por intentos fallidos; se desbloquea sola el #{auto_unlock_time(user)}")
  end

  # Only superadmins can unlock an account by hand.
  def unlock_account_button(user, label: "Desbloquear")
    return unless current_user.superadmin? && user.access_locked?

    button_to label, unlock_user_path(user), method: :patch,
              data: { turbo_confirm: "¿Desbloquear la cuenta de #{user.email}?" },
              class: "btn btn-sm btn-outline-warning"
  end
end
