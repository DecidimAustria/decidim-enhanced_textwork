# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # Resolve only local signed ActiveStorage blobs attached to Core EditorImages
    # in this organization. Never fetch addresses supplied in editor HTML.
    class EditorDocumentInput
      attr_reader :skipped_images, :skipped_video

      def initialize(html, organization, images: true)
        @fragment = Nokogiri::HTML.fragment(html.to_s)
        @organization = organization
        @images = images
        @skipped_images = 0
        @skipped_video = @fragment.css("video,iframe,object,embed,[data-video]").any?
        @fragment.css("script,style,video,iframe,object,embed,[data-video]").remove
      end

      def blocks
        @blocks = []
        @fragment.children.each { |node| parse_node(node) }
        @blocks
      end

      private

      def heading?(node) = node.name.match?(/\Ah[1-6]\z/) && node.text.strip.present?

      def parse_node(node)
        if heading?(node)
          @blocks << { kind: "heading", depth: node.name[1].to_i.clamp(1, 3), body: node.text.strip }
          node.css("img").each { |image| @blocks << image_block(image) }
        elsif %w(ul ol).include?(node.name)
          copy = node.dup
          copy.css("img").remove
          append_text(Markdown.inline(copy))
          node.css("img").each { |image| @blocks << image_block(image) }
        elsif node.name == "p" || node.text?
          parse_text(node)
        elsif node.name == "img"
          @blocks << image_block(node)
        else
          node.children.each { |child| parse_node(child) }
        end
        @blocks.compact!
      end

      def parse_text(node)
        buffer = []
        split_inline(node).each do |part|
          if part.is_a?(Hash)
            append_text(buffer.map { |item| Markdown.inline(item) }.join)
            buffer = []
            @blocks << part
          else
            buffer << part
          end
        end
        append_text(buffer.map { |item| Markdown.inline(item) }.join)
      end

      def append_text(text)
        @blocks << { kind: "paragraph", body: text.strip } if text.strip.present?
      end

      def split_inline(node)
        return [node.dup] if node.text?
        return [image_block(node)].compact if node.name == "img"

        result = []
        wrapper = node.dup(0)
        node.children.flat_map { |child| split_inline(child) }.each do |part|
          if part.is_a?(Hash)
            result << wrapper if wrapper.children.any?
            result << part
            wrapper = node.dup(0)
          else
            wrapper.add_child(part)
          end
        end
        result << wrapper if wrapper.children.any?
        result
      end

      def image_block(node)
        image = resolve_image(node["src"]) if @images
        unless image
          @skipped_images += 1
          return
        end
        { kind: "image", editor_image: image, image_alt: node["alt"].to_s.first(2000) }
      end

      def resolve_image(address)
        path = URI.parse(address.to_s).path
        signed_id = path.match(%r{/rails/active_storage/(?:blobs|representations)/(?:redirect/|proxy/)?([^/]+)})&.captures&.first
        return unless signed_id

        blob = ActiveStorage::Blob.find_signed(signed_id)
        return unless blob

        Decidim::EditorImage.where(organization: @organization).joins(file_attachment: :blob)
                            .find_by(active_storage_blobs: { id: blob.id })
      rescue URI::InvalidURIError, ActiveSupport::MessageVerifier::InvalidSignature
        nil
      end
    end
  end
end
