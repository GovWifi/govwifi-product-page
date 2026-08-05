class Chunk < ApplicationRecord
  belongs_to :document

  has_neighbors :embedding

  validates :content, presence: true
  validates :position, presence: true,
                       uniqueness: { scope: :document_id },
                       numericality: { greater_than_or_equal_to: 0 }

  def citation
    {
      source_type: document.source_type,
      path:        document.relative_path,
      title:       document.title,
      url:         document.url,
      heading:     heading_chain
    }
  end
end
