require "rails_helper"

RSpec.describe Retrieval::Retriever do
  # We stub the pgvector query at the Chunk relation level so these
  # tests don't need a real vector index — they focus on ranking,
  # thresholding, and top-k selection.
  #
  # A separate integration spec (deferred to when we run the full stack)
  # verifies the pgvector round-trip against real Postgres.

  let(:query_vector) { Array.new(1536, 0.0) }

  def stub_candidates(chunks_with_distance)
    relation = double("Chunk::ActiveRecord_Relation")
    allow(Chunk).to receive(:nearest_neighbors).and_return(relation)
    allow(relation).to receive(:includes).and_return(relation)
    allow(relation).to receive(:limit).and_return(chunks_with_distance)
  end

  def chunk_with_distance(source_type:, distance:)
    doc = build_stubbed(:document, source_type: source_type)
    chunk = build_stubbed(:chunk, document: doc)
    allow(chunk).to receive(:neighbor_distance).and_return(distance)
    chunk
  end

  it "returns results ordered by rank-adjusted score (highest first)" do
    stub_candidates([
      chunk_with_distance(source_type: "dev-docs",     distance: 0.20),  # sim 0.80 * 1.00 = 0.800
      chunk_with_distance(source_type: "product-page", distance: 0.30),  # sim 0.70 * 1.15 = 0.805
      chunk_with_distance(source_type: "tech-docs",    distance: 0.40)   # sim 0.60 * 1.05 = 0.630
    ])

    results = described_class.new.call(query_vector)

    expect(results.map { |r| r.chunk.document.source_type }).to eq(
      %w[product-page dev-docs tech-docs]
    )
  end

  it "drops candidates below the similarity threshold" do
    stub_candidates([
      chunk_with_distance(source_type: "product-page", distance: 0.10),  # sim 0.90 — kept
      chunk_with_distance(source_type: "product-page", distance: 0.95)   # sim 0.05 — dropped
    ])

    results = described_class.new(threshold: 0.2).call(query_vector)

    expect(results.size).to eq(1)
    expect(results.first.similarity).to be_within(0.001).of(0.9)
  end

  it "returns at most k results" do
    chunks = Array.new(20) { chunk_with_distance(source_type: "product-page", distance: 0.1) }
    stub_candidates(chunks)

    results = described_class.new(k: 3).call(query_vector)

    expect(results.size).to eq(3)
  end
end
