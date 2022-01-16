# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # This helper include some methods for rendering paragraphs dynamic maps.
    module MapHelper
      include Decidim::ApplicationHelper
      # Serialize a collection of geocoded paragraphs to be used by the dynamic map component
      #
      # geocoded_paragraphs - A collection of geocoded paragraphs
      def paragraphs_data_for_map(geocoded_paragraphs)
        geocoded_paragraphs.map do |paragraph|
          paragraph_data_for_map(paragraph)
        end
      end

      def paragraph_data_for_map(paragraph)
        paragraph
          .slice(:latitude, :longitude, :address)
          .merge(
            title: decidim_html_escape(present(paragraph).title),
            body: html_truncate(decidim_sanitize(present(paragraph).body), length: 100),
            icon: icon("paragraphs", width: 40, height: 70, remove_icon_class: true),
            link: paragraph_path(paragraph)
          )
      end

      def paragraph_preview_data_for_map(paragraph)
        {
          type: "drag-marker",
          marker: paragraph.slice(
            :latitude,
            :longitude,
            :address
          ).merge(
            icon: icon("paragraphs", width: 40, height: 70, remove_icon_class: true)
          )
        }
      end

      def has_position?(paragraph)
        return if paragraph.address.blank?

        paragraph.latitude.present? && paragraph.longitude.present?
      end
    end
  end
end
