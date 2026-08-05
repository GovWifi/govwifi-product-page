require "digest"

module Ingest
  module Loaders
    class TxtLoader
      def initialize(path)
        @path = path.to_s
      end

      def call
        raw = File.read(@path)

        LoadedDocument.new(
          title:            default_title,
          text:             raw.strip,
          raw_content_hash: Digest::SHA256.hexdigest(raw)
        )
      end

      private

      def default_title
        File.basename(@path, ".*").tr("_-", " ").capitalize
      end
    end
  end
end
