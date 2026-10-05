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
end
