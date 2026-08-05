require "yaml"

module Ingest
  module Loaders
    # Middleman/Jekyll-style YAML front matter:
    #
    #   ---
    #   title: Get started
    #   ---
    #   # Heading
    #
    # Returns [attrs, remaining_body]. If no front matter, returns [{}, source].
    module FrontMatter
      DELIMITER = /\A---\s*\n(.*?)\n---\s*\n/m

      def self.split(source)
        return [{}, source] unless source =~ DELIMITER

        attrs = YAML.safe_load(Regexp.last_match(1)) || {}
        [attrs, source.sub(DELIMITER, "")]
      rescue Psych::SyntaxError
        [{}, source]
      end
    end
  end
end
