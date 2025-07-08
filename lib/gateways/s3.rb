require "aws-sdk-s3"

module Gateways
  class S3
    def initialize(bucket:, key:, region: "eu-west-2")
      @bucket = bucket
      @key = key
      @client = Aws::S3::Client.new(region: region)
    end

    def read
      client.get_object(bucket: bucket, key: key).body.read
    end

    private

    attr_reader :bucket, :key, :client
  end
end
