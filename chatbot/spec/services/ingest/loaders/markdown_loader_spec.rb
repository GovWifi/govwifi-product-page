require "rails_helper"

RSpec.describe Ingest::Loaders::MarkdownLoader do
  let(:fixture) { Rails.root.join("spec/fixtures/sample_docs/get-started.md") }

  it "extracts the title from YAML front matter when present" do
    doc = described_class.new(fixture).call
    expect(doc.title).to eq("Get started")
  end

  it "keeps the body content (without front matter) as-is" do
    doc = described_class.new(fixture).call
    expect(doc.text).to include("# Get started with GovWifi")
    expect(doc.text).not_to include("---")
  end

  it "produces a content hash of the raw file bytes" do
    doc  = described_class.new(fixture).call
    hash = Digest::SHA256.hexdigest(File.read(fixture))
    expect(doc.raw_content_hash).to eq(hash)
  end

  it "falls back to the first H1 when no front-matter title exists" do
    Tempfile.create(["no-fm", ".md"]) do |f|
      f.write("# The Real Title\n\nBody.")
      f.rewind
      expect(described_class.new(f.path).call.title).to eq("The Real Title")
    end
  end
end
