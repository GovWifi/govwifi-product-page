require "rails_helper"

RSpec.describe Ingest::Loaders::TxtLoader do
  let(:fixture) { Rails.root.join("spec/fixtures/sample_docs/plain.txt") }

  it "returns the file body as text and derives a title from the filename" do
    doc = described_class.new(fixture).call
    expect(doc.title).to eq("Plain")
    expect(doc.text).to include("Plain text file content.")
  end
end
