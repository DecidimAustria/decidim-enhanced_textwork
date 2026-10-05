# frozen_string_literal: true

require "kramdown"
require "zip"
module Decidim
  module EnhancedTextwork
    class DocumentInput
      class Invalid < StandardError; end
      MAX_UPLOAD = 2.megabytes
      MAX_XML = 5.megabytes
      WORD_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
      def self.read(upload)
        raise Invalid if upload.size > MAX_UPLOAD

        data = upload.read(MAX_UPLOAD + 1)
        raise Invalid if data.bytesize > MAX_UPLOAD

        case File.extname(upload.original_filename).downcase
        when ".md", ".markdown"
          text = data.force_encoding(Encoding::UTF_8)
          raise Invalid unless text.valid_encoding?

          Kramdown::Document.new(text).to_html
        when ".odt" then odt(xml_entry(data, "content.xml"))
        when ".docx" then word(xml_entry(data, "word/document.xml"))
        else raise Invalid
        end
      rescue Zip::Error, Nokogiri::XML::SyntaxError, ArgumentError
        raise Invalid
      end

      def self.xml_entry(data, name)
        xml = nil
        Zip::File.open_buffer(data) do |zip|
          entry = zip.find_entry(name)
          raise Invalid unless entry && entry.size <= MAX_XML

          xml = entry.get_input_stream.read(MAX_XML + 1)
        end
        raise Invalid if xml.bytesize > MAX_XML || xml.match?(/<!DOCTYPE|<!ENTITY/i)

        Nokogiri::XML(xml) { |config| config.strict.nonet }
      end

      def self.odt(document)
        namespaces = { "office" => "urn:oasis:names:tc:opendocument:xmlns:office:1.0", "text" => "urn:oasis:names:tc:opendocument:xmlns:text:1.0" }
        document.xpath("//office:body/office:text/*", namespaces).map { |node| odt_node(node, namespaces) }.join
      end

      def self.odt_node(node, namespaces)
        case node.name
        when "h"
          level = node.attribute_with_ns("outline-level", namespaces["text"])&.value.to_i.clamp(1, 3)
          "<h#{level}>#{ERB::Util.html_escape(node.text)}</h#{level}>"
        when "p" then "<p>#{ERB::Util.html_escape(node.text)}</p>"
        when "list" then "<ul>#{node.element_children.map { |item| "<li>#{item.element_children.map { |child| odt_node(child, namespaces) }.join}</li>" }.join}</ul>"
        else ""
        end
      end

      def self.word(document)
        namespaces = { "w" => WORD_NS }
        output = []
        list = []
        document.xpath("//w:body/w:p", namespaces).each do |paragraph|
          content = word_runs(paragraph, namespaces)
          if paragraph.at_xpath("./w:pPr/w:numPr", namespaces)
            list << "<li>#{content}</li>"
            next
          end
          unless list.empty?
            output << "<ul>#{list.join}</ul>"
            list = []
          end
          tag = word_tag(paragraph, namespaces)
          output << "<#{tag}>#{content}</#{tag}>" unless content.empty?
        end
        output << "<ul>#{list.join}</ul>" unless list.empty?
        output.join
      end

      def self.word_tag(paragraph, namespaces)
        style = paragraph.at_xpath("./w:pPr/w:pStyle", namespaces)&.attribute_with_ns("val", WORD_NS)&.value.to_s
        level = style.match(/(?:heading|überschrift)[ -]?([1-6])/i)&.captures&.first
        level ? "h#{level.to_i.clamp(1, 3)}" : "p"
      end

      def self.word_runs(paragraph, namespaces)
        paragraph.xpath(".//w:r", namespaces).map do |run|
          text = run.xpath("./w:t | ./w:br | ./w:tab", namespaces).map { |node| node.name == "t" ? ERB::Util.html_escape(node.text) : "<br>" }.join
          text = "<strong>#{text}</strong>" if run.at_xpath("./w:rPr/w:b[not(@w:val='0')]", namespaces)
          text = "<em>#{text}</em>" if run.at_xpath("./w:rPr/w:i[not(@w:val='0')]", namespaces)
          text
        end.join
      end
    end
  end
end
