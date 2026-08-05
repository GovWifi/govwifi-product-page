module Retrieval
  # pgvector cosine-similarity retrieval with source_type re-ranking.
  #
  #   Retriever.new.call(query_vector) # => [Result, Result, ...]
  #
  # Over-fetches (k * 2) to allow the ranker to reorder without losing
  # good candidates that were narrowly beaten on raw similarity.
  class Retriever
    K_DEFAULT         = 8
    THRESHOLD_DEFAULT = 0.2
    OVERFETCH_FACTOR  = 2

    Result = Data.define(:chunk, :similarity, :score) do
      def to_citation
        chunk.citation.merge(score: score.round(3))
      end
    end

    def initialize(k: K_DEFAULT, threshold: THRESHOLD_DEFAULT, ranker: Ranker.new)
      @k         = k
      @threshold = threshold
      @ranker    = ranker
    end

    def call(query_vector)
      candidates = Chunk.nearest_neighbors(:embedding, query_vector, distance: "cosine")
                        .includes(:document)
                        .limit(@k * OVERFETCH_FACTOR)

      candidates
        .map { |chunk| build_result(chunk) }
        .select { |result| result.similarity >= @threshold }
        .sort_by { |result| -result.score }
        .first(@k)
    end

    private

    def build_result(chunk)
      similarity = 1.0 - chunk.neighbor_distance.to_f
      Result.new(
        chunk:      chunk,
        similarity: similarity,
        score:      @ranker.score(chunk: chunk, similarity: similarity)
      )
    end
  end
end
