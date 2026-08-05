require "rails_helper"

RSpec.describe Ingest::Chunker do
  subject(:chunker) { described_class.new }

  it "returns a single chunk for short content, prefixed with the heading chain" do
    chunks = chunker.call("# Get started\n\nSign up here.")

    expect(chunks.size).to eq(1)
    expect(chunks.first.heading_chain).to eq("Get started")
    expect(chunks.first.content).to include("Get started")
    expect(chunks.first.content).to include("Sign up here.")
  end

  it "builds a nested heading chain across H1 > H2 > H3" do
    text = <<~MD
      # Guide

      Intro paragraph.

      ## Sign up

      Step one.

      ### Verify

      Check inbox.
    MD

    chunks = chunker.call(text)

    expect(chunks.map(&:heading_chain)).to eq([
      "Guide",
      "Guide > Sign up",
      "Guide > Sign up > Verify"
    ])
  end

  it "splits long sections into multiple chunks with heading prefix preserved" do
    paragraph = "This is a paragraph. " * 200   # ~4000 chars
    text = "# Long section\n\n#{paragraph}\n\n#{paragraph}"

    chunks = chunker.call(text)

    expect(chunks.size).to be >= 2
    chunks.each do |chunk|
      expect(chunk.content).to start_with("Long section")
    end
  end

  it "monotonically increases position across sections" do
    text = <<~MD
      # A

      Body A.

      # B

      Body B.

      # C

      Body C.
    MD

    positions = chunker.call(text).map(&:position)
    expect(positions).to eq(positions.sort)
    expect(positions.uniq).to eq(positions)
  end

  it "estimates token_count via char count" do
    chunks = chunker.call("# H\n\nsome content here")
    expected = (chunks.first.content.length / 4.0).round
    expect(chunks.first.token_count).to eq(expected)
  end
end
