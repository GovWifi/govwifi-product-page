require "open-uri"

module Tasks
  class FetchOrgs
    def self.call
      object_url = "https://govwifi-production-product-page-data.s3.eu-west-2.amazonaws.com/organisations.yml"

      data = URI.open(object_url).read

      path = File.expand_path("data/organisations.yml", __dir__)
      File.write(path, data)

      puts "Wrote organisations.yml to: #{path}"
    rescue OpenURI::HTTPError => e
      puts "Failed to fetch organisation data: #{e.message}"
    rescue => e
      puts "Unexpected error: #{e.message}"
    end
  end
end
