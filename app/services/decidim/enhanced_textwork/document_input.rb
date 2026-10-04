# frozen_string_literal: true

require "kramdown"
require "zip"
module Decidim
  module EnhancedTextwork
    class DocumentInput
      class Invalid < StandardError; end
      MAX_UPLOAD = 2.megabytes
      MAX_XML = 5.megabytes
      def self.read(upload)
        raise Invalid if upload.size > MAX_UPLOAD

        data = upload.read(MAX_UPLOAD + 1)
        raise Invalid if data.bytesize > MAX_UPLOAD

        case File.extname(upload.original_filename).downcase
        when ".md", ".markdown"
          text = data.force_encoding(Encoding::UTF_8)
          raise Invalid unless text.valid_encoding?

          Kramdown::Document.new(text).to_html
        when ".odt"
          xml = nil
          Zip::File.open_buffer(data) do |zip|
            entry = zip.find_entry("content.xml")
            raise Invalid unless entry && entry.size <= MAX_XML

            xml = entry.get_input_stream.read(MAX_XML + 1)
          end
          raise Invalid if xml.bytesize > MAX_XML || xml.include?("<!DOCTYPE") || xml.include?("<!ENTITY")

          document = Nokogiri::XML(xml) { |config| config.strict.nonet }
          ns = { "office" => "urn:oasis:names:tc:opendocument:xmlns:office:1.0", "text" => "urn:oasis:names:tc:opendocument:xmlns:text:1.0" }
          document.xpath("//office:body/office:text//text:h | //office:body/office:text//text:p", ns).map do |node|
            level = node.attribute_with_ns("outline-level", ns["text"])&.value.to_i.clamp(1, 6)
            tag = node.name == "h" ? "h#{level}" : "p"
            "<#{tag}>#{ERB::Util.html_escape(node.text)}</#{tag}>"
          end.join
        else
          raise Invalid
        end
      rescue Zip::Error, Nokogiri::XML::SyntaxError, ArgumentError
        raise Invalid
      end
    end
  end
end
