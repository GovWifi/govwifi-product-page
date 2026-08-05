class Document < ApplicationRecord
  SOURCE_TYPES = %w[product-page tech-docs dev-docs zendesk].freeze

  has_many :chunks, dependent: :destroy

  validates :source_type, presence: true, inclusion: { in: SOURCE_TYPES }
  validates :relative_path, presence: true, uniqueness: { scope: :source_type }
  validates :content_hash, presence: true

  scope :by_source, ->(source_type) { where(source_type: source_type) }

  def source_priority
    SOURCE_PRIORITIES.fetch(source_type, 1.0)
  end

  SOURCE_PRIORITIES = {
    "product-page" => 1.15,
    "tech-docs"    => 1.05,
    "dev-docs"     => 1.00,
    "zendesk"      => 0.85
  }.freeze
end
