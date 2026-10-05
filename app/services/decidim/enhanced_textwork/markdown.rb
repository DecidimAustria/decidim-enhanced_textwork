# frozen_string_literal: true

require "kramdown"
module Decidim
  module EnhancedTextwork
    module Markdown
      TAGS = %w(p br strong em a ul ol li).freeze
      def self.render(text)
        html = Kramdown::Document.new(ERB::Util.html_escape(text.to_s), input: "Kramdown", parse_block_html: false, parse_span_html: false).to_html
        Rails::Html::SafeListSanitizer.new.sanitize(html, tags: TAGS, attributes: %w(href title)).html_safe
      end

      def self.from_html(html)
        fragment = Nokogiri::HTML.fragment(html.to_s)
        fragment.css("script,style,iframe,object").remove
        fragment.children.filter_map do |node|
          next if node.text.strip.empty?

          heading = node.name.match?(/\Ah[1-6]\z/)
          { kind: heading ? "heading" : "paragraph", depth: heading ? node.name[1].to_i.clamp(1, 3) : 1,
            body: heading ? node.text.strip : inline(node).strip }
        end
      end

      # Each branch maps one permitted inline/list element to Markdown.
      # rubocop:disable Metrics/CyclomaticComplexity
      def self.inline(node)
        return node.text if node.text?

        content = node.children.map { |child| inline(child) }.join
        case node.name
        when "strong", "b" then "**#{content}**"
        when "em", "i" then "*#{content}*"
        when "a"
          url = node["href"].to_s
          url.match?(%r{\A(?:https?://|mailto:)}i) ? "[#{content}](#{url.gsub(/[()\s]/, "")})" : content
        when "br" then "\n"
        when "li"
          marker = node.parent.name == "ol" ? "#{node.xpath("preceding-sibling::li").size + 1}." : "-"
          "#{marker} #{content.strip}\n"
        when "p" then "#{content}\n\n"
        else content
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity
    end
  end
end
