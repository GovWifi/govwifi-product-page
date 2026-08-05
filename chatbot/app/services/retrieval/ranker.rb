module Retrieval
  # Applies source_type weighting to a raw similarity score.
  # Weights live on Document#source_priority (see docs/architecture.md §7).
  #
  # Injectable so tests can substitute a fake ranker or a deterministic one.
  class Ranker
    def score(chunk:, similarity:)
      similarity * chunk.document.source_priority
    end
  end
end
