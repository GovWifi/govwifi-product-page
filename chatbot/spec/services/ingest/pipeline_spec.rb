require "rails_helper"

RSpec.describe Ingest::Pipeline do
  let(:fixture_path) { Rails.root.join("spec/fixtures/sample_docs/get-started.md") }
  let(:file) do
    Ingest::Sources::LocalRepo::IndexableFile.new(
      source_type:   "product-page",
      absolute_path: fixture_path.to_s,
      relative_path: "get-started.md",
      url:           "https://www.wifi.service.gov.uk/get-started/"
    )
  end

  let(:embedder) do
    instance_double(Ingest::Embedder).tap do |e|
      allow(e).to receive(:call) { |texts| texts.map { Array.new(1536) { 0.01 } } }
    end
  end

  subject(:pipeline) { described_class.new(embedder: embedder) }

  it "creates a Document with title, url, and content hash from the loaded file" do
    result = pipeline.call(file)

    expect(result.status).to eq(:indexed)
    expect(result.document.title).to eq("Get started")
    expect(result.document.url).to eq("https://www.wifi.service.gov.uk/get-started/")
    expect(result.document.content_hash).to eq(Digest::SHA256.hexdigest(File.read(fixture_path)))
  end

  it "creates chunks with embeddings" do
    result = pipeline.call(file)

    expect(result.chunks_added).to be > 0
    expect(result.document.chunks.count).to eq(result.chunks_added)
    expect(result.document.chunks.pluck(:embedding).all? { |e| e.is_a?(Array) && e.size == 1536 }).to be true
  end

  it "skips re-indexing when content_hash is unchanged" do
    pipeline.call(file)

    expect(embedder).not_to receive(:call)
    result = pipeline.call(file)
    expect(result.status).to eq(:skipped)
  end

  it "updates and re-embeds when the file content changes" do
    pipeline.call(file)
    doc = Document.find_by!(relative_path: "get-started.md")
    doc.update!(content_hash: "stale")

    result = pipeline.call(file)
    expect(result.status).to eq(:updated)
    expect(result.document.content_hash).not_to eq("stale")
  end
end
