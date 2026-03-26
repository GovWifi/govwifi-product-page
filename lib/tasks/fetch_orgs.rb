require "open-uri"

module Tasks
  class FetchOrgs
    OBJECT_URL = "https://govwifi-production-product-page-data.s3.eu-west-2.amazonaws.com/organisations.yml".freeze
    OUTPUT_PATH = "data/organisations.yml".freeze

    def self.call
      data = fetch_data
      data = sanitise_data(data)
      path = output_path
      File.write(path, data)

      puts "Wrote organisations.yml to: #{path}"
      true
    rescue OpenURI::HTTPError => e
      puts "Failed to fetch organisation data: #{e.message}"
      false
    rescue StandardError => e
      puts "Unexpected error: #{e.message}"
      false
    end

    def self.fetch_data
      URI.open(OBJECT_URL).read
    end

    def self.sanitise_data(data)
      # strip the leading '---' if present
      data = data.sub(/\A---\s*\n/, "")
      # strip spaces and quotation marks if present
      normalise_organisation_lines(data)
    end

    def self.output_path
      File.expand_path(OUTPUT_PATH, Dir.pwd)
    end

    def self.normalise_organisation_lines(data)
      data.lines.map do |line|
        next line unless line.start_with?("- ")

        name = line.sub(/\A-\s*/, "").strip

        if (name.start_with?('"') && name.end_with?('"')) || (name.start_with?("'") && name.end_with?("'"))
          name = name[1..-2]
        end

        "- #{name.strip}\n"
      end.join
    end
  end
end
