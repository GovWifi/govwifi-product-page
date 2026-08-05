require "pathname"

module Ingest
  module Sources
    # Enumerates indexable files under a configured root directory,
    # applying skip_patterns and dropping files with no matching loader.
    #
    # Yields IndexableFile records (path metadata only; no I/O until the
    # pipeline calls the loader).
    class LocalRepo
      IndexableFile = Data.define(:source_type, :absolute_path, :relative_path, :url)

      def initialize(source_type:, root:, url_prefix:, skip_patterns: [])
        @source_type   = source_type
        @root          = resolve(root)
        @url_prefix    = url_prefix.to_s.chomp("/")
        @skip_patterns = Array(skip_patterns)
      end

      def each
        return enum_for(:each) unless block_given?

        Dir.glob(@root.join("**", "*").to_s).sort.each do |path|
          next unless File.file?(path)
          relative = Pathname(path).relative_path_from(@root).to_s
          next if skip?(relative)
          next unless supported?(path)

          yield IndexableFile.new(
            source_type:   @source_type,
            absolute_path: path,
            relative_path: relative,
            url:           url_for(relative)
          )
        end
      end

      def self.from_config(config_path: Rails.root.join("config/ai_sources.yml"))
        yaml = YAML.safe_load_file(config_path)
        skip = yaml["skip_patterns"] || []
        (yaml["sources"] || []).map do |source|
          new(
            source_type:   source["source_type"],
            root:          source["root"],
            url_prefix:    source["url_prefix"],
            skip_patterns: skip
          )
        end
      end

      private

      def resolve(root)
        path = Pathname(root.to_s)
        path.absolute? ? path : Rails.root.join(root.to_s).expand_path
      end

      def skip?(relative_path)
        @skip_patterns.any? { |pattern| File.fnmatch?(pattern, relative_path, File::FNM_PATHNAME | File::FNM_EXTGLOB) }
      end

      def supported?(path)
        Ingest::Loaders.for(path)
        true
      rescue Ingest::Loaders::UnsupportedFileType
        false
      end

      def url_for(relative_path)
        slug = relative_path
                 .sub(/\Asource\//, "")
                 .sub(/\.html\.md\.erb\z/, "/")
                 .sub(/\.html\.erb\z/, "/")
                 .sub(/\.md\z/, "/")
                 .sub(/\.html?\z/, "/")
                 .sub(/\Aindex\/\z/, "")
                 .sub(/\/index\/\z/, "/")

        "#{@url_prefix}/#{slug}"
      end
    end
  end
end
