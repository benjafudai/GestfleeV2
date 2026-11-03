# Excepción del superadmin: activa o quita una sección a una empresa o a un
# usuario. Con expires_on deja de aplicar al día siguiente de esa fecha.
class FeatureOverride < ApplicationRecord
  has_paper_trail

  belongs_to :subject, polymorphic: true
  belongs_to :granted_by, class_name: "User", optional: true

  validates :feature, inclusion: { in: ->(_) { Feature.keys } }
  validates :enabled, inclusion: { in: [true, false] }
  validates :subject_type, inclusion: { in: %w[Company User] }
  validates :feature, uniqueness: { scope: [:subject_type, :subject_id] }

  after_commit { Current.feature_overrides = nil }

  scope :current, -> { where(expires_on: nil).or(where(expires_on: Date.current..)) }

  # Las excepciones se consultan muchas veces por página (menú, tablero,
  # controlador); se cargan una sola vez por sujeto y petición.
  def self.current_for(subject, key)
    cache = (Current.feature_overrides ||= {})
    by_feature = cache[[subject.class.name, subject.id]] ||= current.where(subject: subject).index_by(&:feature)
    by_feature[key.to_s]
  end

  def expired?
    expires_on.present? && expires_on < Date.current
  end
end
