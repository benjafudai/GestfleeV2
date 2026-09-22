module VehicleAssignable
  extend ActiveSupport::Concern

  included do
    validate :actor_must_be_assigned_to_vehicle, on: :create
  end

  class_methods do
    # Declara qué asociación representa a "quién hace esto" (reporter, user, etc.)
    def vehicle_assignable_actor(association_name)
      define_method(:vehicle_assignable_actor) { send(association_name) }
    end
  end

  private

  def actor_must_be_assigned_to_vehicle
    actor = vehicle_assignable_actor
    return unless actor && vehicle
    return unless actor.chofer?
    return if actor.active_assignment&.vehicle_id == vehicle_id

    errors.add(:vehicle, "debe ser el que tienes asignado actualmente")
  end
end
