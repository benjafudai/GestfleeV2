module UsersHelper
  ROLE_LABELS = {
    'admin'      => 'Administrador',
    'chofer'     => 'Chofer',
    'mecanico'   => 'Mecánico',
    'analista'   => 'Analista',
    'superadmin' => 'Superadministrador',
    'bodeguero'  => 'Bodeguero'
  }.freeze

  # Ícono (Bootstrap Icons) de cada rol.
  ROLE_ICONS = {
    'admin'      => 'bi-person-gear',
    'chofer'     => 'bi-truck',
    'mecanico'   => 'bi-wrench-adjustable',
    'analista'   => 'bi-graph-up',
    'superadmin' => 'bi-shield-lock',
    'bodeguero'  => 'bi-box-seam'
  }.freeze

  # Solo los roles con más permisos llevan color; el resto, etiqueta neutra.
  ROLE_PILL_TONES = {
    'superadmin' => 'purple',
    'admin'      => 'blue'
  }.freeze

  # Ícono de cada tipo de documento personal.
  USER_DOC_ICONS = {
    'licencia_conducir'     => 'bi-person-vcard',
    'carnet_identidad'      => 'bi-person-badge',
    'examen_preocupacional' => 'bi-heart-pulse',
    'contrato'              => 'bi-file-earmark-text'
  }.freeze

  # Roles que un administrador de empresa puede asignar (los mismos que acepta
  # UsersController); un superadministrador puede asignar cualquiera.
  ADMIN_ASSIGNABLE_ROLES = %w[chofer mecanico analista bodeguero].freeze

  # Quien edita solo puede guardar la cuenta si puede asignar el rol que ya
  # tiene: un admin no puede editar a otro admin (ni a sí mismo).
  def can_edit_user?(user)
    current_user.superadmin? || ADMIN_ASSIGNABLE_ROLES.include?(user.role_was.to_s)
  end

  def role_label(role)
    ROLE_LABELS[role.to_s] || role.to_s.humanize
  end

  def role_icon(role)
    ROLE_ICONS.fetch(role.to_s, 'bi-person')
  end

  # Etiqueta del rol con su ícono: "Chofer", "Administrador"...
  def role_pill(role)
    classes = ['pill', 'gap-1', ROLE_PILL_TONES[role.to_s]].compact.join(' ')
    tag.span(safe_join([tag.i(class: "bi #{role_icon(role)}", "aria-hidden": true), role_label(role)]), class: classes)
  end

  # Opciones del selector de rol. Si el usuario ya tiene un rol que quien edita
  # no puede asignar (un admin editando a otro admin), se muestra igual para que
  # el formulario no aparezca con un rol distinto al real.
  def role_options(available_roles, current_role = nil)
    roles = Array(available_roles).map(&:to_s)
    roles = [current_role.to_s] + roles if current_role.present? && !roles.include?(current_role.to_s)
    roles.map { |r| [role_label(r), r] }
  end

  # Círculo con la inicial del correo (mismo estilo que el avatar de la barra superior).
  def user_avatar(user, size: nil)
    tag.span(user.email.to_s.first.to_s.upcase, class: ['gf-avatar', ("gf-avatar-lg" if size == :lg)].compact.join(' '),
             "aria-hidden": true)
  end

  # When a locked account unlocks on its own (Devise :time unlock strategy).
  def auto_unlock_time(user)
    (user.locked_at + User.unlock_in).strftime("%d/%m/%Y %H:%M")
  end

  def account_locked_badge(user)
    return unless user.access_locked?

    tag.span(safe_join([tag.i(class: "bi bi-lock-fill me-1", "aria-hidden": true), "Bloqueada"]),
             class: "badge text-bg-danger",
             title: "Bloqueada por intentos fallidos; se desbloquea sola el #{auto_unlock_time(user)}")
  end

  # Only superadmins can unlock an account by hand.
  # icon_only: botón cuadrado solo con ícono, para la columna de acciones de una tabla.
  def unlock_account_button(user, label: "Desbloquear", icon_only: false)
    return unless current_user.superadmin? && user.access_locked?

    confirm = { turbo_confirm: "¿Desbloquear la cuenta de #{user.email}?" }

    if icon_only
      button_to unlock_user_path(user), method: :patch, data: confirm,
                class: "btn btn-sm btn-outline-warning", title: label, "aria-label": label do
        tag.i(class: "bi bi-unlock")
      end
    else
      button_to unlock_user_path(user), method: :patch, data: confirm,
                class: "btn btn-sm btn-outline-warning text-nowrap" do
        safe_join([tag.i(class: "bi bi-unlock me-1", "aria-hidden": true), label])
      end
    end
  end

  # Vencimiento de un documento: "Vence el 18 de octubre de 2026 · en 4 días",
  # "Vence hoy, 14 de octubre de 2026", "Venció el 3 de octubre de 2026 · hace 11 días".
  def user_document_due_text(document)
    return "Sin fecha de vencimiento" if document.due_on.blank?

    date = l(document.due_on, format: :long)
    days = (document.due_on - Date.current).to_i

    if days.zero?
      "Vence hoy, #{date}"
    elsif days.positive?
      due_text_with_distance("Vence el #{date}", "en #{days_in_words(days)}")
    else
      due_text_with_distance("Venció el #{date}", "hace #{days_in_words(-days)}")
    end
  end

  # Ícono del tipo de documento en un círculo del mismo tono que su estado.
  def user_document_icon_circle(document, extra_class: nil)
    tone = status_tone(document.status)
    icon = USER_DOC_ICONS.fetch(document.doc_type.to_s, 'bi-file-earmark')
    tag.span(tag.i(class: "bi #{icon}"),
             class: ["gf-action-icon bg-#{tone}-subtle text-#{tone}-emphasis", extra_class].compact.join(' '),
             "aria-hidden": true)
  end

  # Ícono del archivo de un documento personal: PDF (rojo, como en los
  # documentos del vehículo) o imagen (azul) cuando colored: true.
  def user_document_file_icon(file, colored: false)
    image = file.content_type.to_s.start_with?("image/")
    icon = image ? "bi-file-earmark-image" : "bi-file-earmark-pdf"
    colored ? "#{icon} #{image ? 'text-primary' : 'text-danger'}" : icon
  end

  private

  # "Vence el … · en 4 días" en una línea; en el teléfono la distancia pasa a
  # su propia línea, sin el «·», para que el separador no quede colgando.
  def due_text_with_distance(due, distance)
    safe_join([due, tag.span(" · ", class: "d-none d-sm-inline"), tag.span(distance, class: "d-block d-sm-inline text-nowrap")])
  end

  # "4 días", "3 meses", "más de 1 año".
  def days_in_words(days)
    if days < 60
      pluralize(days, "día", plural: "días")
    elsif days < 365
      pluralize((days / 30.0).round, "mes", plural: "meses")
    else
      "más de #{pluralize(days / 365, 'año', plural: 'años')}"
    end
  end
end
