require "rails_helper"

RSpec.describe Ingest::Loaders::MdErbLoader do
  let(:fixture) { Rails.root.join("spec/fixtures/sample_docs/set_up.html.md.erb") }

  it "reads the title from YAML front matter after ERB stripping" do
    doc = described_class.new(fixture).call
    expect(doc.title).to eq("Set up your organisation")
  end

  it "strips ERB comments and tags" do
    doc = described_class.new(fixture).call
    expect(doc.text).not_to include("<%")
    expect(doc.text).not_to include("ERB comment")
  end

  it "preserves markdown headings for downstream chunking" do
    doc = described_class.new(fixture).call
    expect(doc.text).to include("# Set up")
    expect(doc.text).to include("## Requirements")
  end
end
