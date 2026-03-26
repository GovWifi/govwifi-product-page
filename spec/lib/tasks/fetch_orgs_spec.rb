require "rspec"
require_relative "../../../lib/tasks/fetch_orgs"

RSpec.describe Tasks::FetchOrgs do
  describe " sanitise data" do
    it "removes YAML front matter and normalises organisation names" do
      raw_data = <<~DATA
        ---
        - " ACAS "
        - 'Cabinet Office'
        -   Department for Education
      DATA

      expect(described_class.sanitise_data(raw_data)).to eq(
        <<~DATA
          - ACAS
          - Cabinet Office
          - Department for Education
        DATA
      )
    end

    it "returns normalised data unchanged when front matter is absent" do
      raw_data = <<~DATA
        - ACAS
        - Home Office
      DATA

      expect(described_class.sanitise_data(raw_data)).to eq(raw_data)
    end
  end

  describe "normalise organisation names" do
    it "normalises whitespace and strips surrounding quotes from list values" do
      raw_data = <<~DATA
        - "  ACAS  "
        - ' Home Office '
        -   Department for Education
      DATA

      expect(described_class.normalise_organisation_lines(raw_data)).to eq(
        <<~DATA
          - ACAS
          - Home Office
          - Department for Education
        DATA
      )
    end
  end
end
