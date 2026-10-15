module SupplyRequestsHelper
  # Etiqueta del estado (la misma que usan los dashboards).
  def supply_request_status_label(status)
    SupplyRequest.human_status(status)
  end

  # Qué significa cada paso del flujo, para la línea de tiempo del detalle.
  SUPPLY_REQUEST_STEP_HINTS = {
    "requested"  => "Se envió el pedido a bodega.",
    "received"   => "Bodega revisó el pedido.",
    "purchasing" => "Se están comprando los repuestos que faltan.",
    "delivered"  => "Se entregaron los repuestos y se descontaron del stock."
  }.freeze

  # Texto e ícono del botón que lleva la solicitud al estado indicado.
  SUPPLY_REQUEST_NEXT_ACTIONS = {
    "received"   => ["Marcar como recibida", "bi-inbox"],
    "purchasing" => ["Pasar a compra", "bi-cart"],
    "delivered"  => ["Entregar repuestos", "bi-box-arrow-right"]
  }.freeze

  def supply_request_step_hint(status)
    SUPPLY_REQUEST_STEP_HINTS[status.to_s]
  end

  def supply_request_next_action(status)
    SUPPLY_REQUEST_NEXT_ACTIONS.fetch(status.to_s) { ["Avanzar a #{supply_request_status_label(status)}", "bi-arrow-right"] }
  end
end
