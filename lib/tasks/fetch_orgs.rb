require_relative "../gateways/s3"

module Tasks
  class FetchOrgs
    def self.call
      gateway = Gateways::S3.new(
        bucket: ENV.fetch("S3_PRODUCT_PAGE_DATA_BUCKET"),
        key: ENV.fetch("S3_ORGANISATION_NAMES_OBJECT_KEY")
      )

      data = gateway.read
      path = File.expand_path("data/organisations.yml", __dir__)
      File.write(path, data)
      puts "Wrote organisations.yml to: #{path}"
    end
  end
end