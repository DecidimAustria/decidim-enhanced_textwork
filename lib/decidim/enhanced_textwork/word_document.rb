# frozen_string_literal: true

require "nokogiri"
require "zip"

module Decidim
  module EnhancedTextwork
    # A text report, not an HTML/Word layout converter. No external files or URLs
    # are fetched when processing document content.
    class WordDocument
      WORD_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"

      def initialize
        @paragraphs = []
      end

      def paragraph(text, heading: false, indent: 0)
        @paragraphs << [text.to_s.gsub(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/, ""), heading, indent]
      end

      def html(content, indent: 0)
        fragment = Nokogiri::HTML.fragment(content.to_s)
        fragment.css("script, style").remove
        fragment.css("br").each { |node| node.replace("\n") }
        fragment.css("p, div, h1, h2, h3, h4, h5, h6, li, blockquote").each do |node|
          node.add_next_sibling(Nokogiri::XML::Text.new("\n", fragment.document))
        end
        fragment.text.split(/\n+/).each { |line| paragraph(line, indent:) unless line.strip.empty? }
      end

      def render
        files = {
          "[Content_Types].xml" => <<~XML,
            <?xml version="1.0" encoding="UTF-8"?>
            <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
              <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
              <Default Extension="xml" ContentType="application/xml"/>
              <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
            </Types>
          XML
          "_rels/.rels" => <<~XML,
            <?xml version="1.0" encoding="UTF-8"?>
            <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
              <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
            </Relationships>
          XML
          "word/document.xml" => document_xml
        }
        Zip::OutputStream.write_buffer do |zip|
          files.each do |path, content|
            zip.put_next_entry(path)
            zip.write(content)
          end
        end.string
      end

      private

      def document_xml
        Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
          xml["w"].document("xmlns:w" => WORD_NS) do
            xml["w"].body do
              @paragraphs.each do |text, heading, indent|
                xml["w"].p do
                  xml["w"].pPr { xml["w"].ind("w:left" => indent * 360) } if indent.positive?
                  xml["w"].r do
                    xml["w"].rPr { xml["w"].b } if heading
                    xml["w"].t(text, "xml:space" => "preserve")
                  end
                end
              end
            end
          end
        end.to_xml
      end
    end
  end
end
