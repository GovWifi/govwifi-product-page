require "rails_helper"

RSpec.describe Ingest::Loaders::HtmlErbLoader do
  let(:fixture) { Rails.root.join("spec/fixtures/sample_docs/page.html.erb") }

  it "strips ERB tags before parsing as HTML" do
    doc = described_class.new(fixture).call
    expect(doc.text).not_to include("<%")
    expect(doc.text).not_to include("%>")
  end

  it "strips nav elements" do
    doc = described_class.new(fixture).call
    expect(doc.text).not_to include("should be stripped")
  end

  it "keeps the visible body copy" do
    doc = described_class.new(fixture).call
    expect(doc.text).to include("How do I connect?")
    expect(doc.text).to include("Detail paragraph.")
  end

  it "hashes the raw source (not the stripped output)" do
    doc  = described_class.new(fixture).call
    hash = Digest::SHA256.hexdigest(File.read(fixture))
    expect(doc.raw_content_hash).to eq(hash)
  end
end
