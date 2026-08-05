require "rails_helper"

RSpec.describe Retrieval::Ranker do
  subject(:ranker) { described_class.new }

  def chunk_for(source_type)
    build(:chunk, document: build(:document, source_type: source_type))
  end

  it "boosts product-page chunks above tech-docs and dev-docs" do
    pp = chunk_for("product-page")
    td = chunk_for("tech-docs")
    dd = chunk_for("dev-docs")

    similarity = 0.7
    pp_score = ranker.score(chunk: pp, similarity: similarity)
    td_score = ranker.score(chunk: td, similarity: similarity)
    dd_score = ranker.score(chunk: dd, similarity: similarity)

    expect(pp_score).to be > td_score
    expect(td_score).to be > dd_score
  end

  it "demotes zendesk chunks below dev-docs" do
    dd = chunk_for("dev-docs")
    zd = chunk_for("zendesk")

    expect(ranker.score(chunk: dd, similarity: 0.5))
      .to be > ranker.score(chunk: zd, similarity: 0.5)
  end
end
