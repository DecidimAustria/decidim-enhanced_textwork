# frozen_string_literal: true

require "cell/partial"

module Decidim
  module EnhancedTextwork
    # This cell renders a paragraphs picker.
    class ParagraphsPickerCell < Decidim::ViewModel
      MAX_PARAGRAPHS = 1000

      def show
        if filtered?
          render :paragraphs
        else
          render
        end
      end

      alias component model

      def filtered?
        !search_text.nil?
      end

      def picker_path
        request.path
      end

      def search_text
        params[:q]
      end

      def more_paragraphs?
        @more_paragraphs ||= more_paragraphs_count.positive?
      end

      def more_paragraphs_count
        @more_paragraphs_count ||= paragraphs_count - MAX_PARAGRAPHS
      end

      def paragraphs_count
        @paragraphs_count ||= filtered_paragraphs.count
      end

      def decorated_paragraphs
        filtered_paragraphs.limit(MAX_PARAGRAPHS).each do |paragraph|
          yield Decidim::EnhancedTextwork::ParagraphPresenter.new(paragraph)
        end
      end

      def filtered_paragraphs
        @filtered_paragraphs ||= if filtered?
                                  paragraphs.where("title::text ILIKE ?", "%#{search_text}%")
                                           .or(paragraphs.where("reference ILIKE ?", "%#{search_text}%"))
                                           .or(paragraphs.where("id::text ILIKE ?", "%#{search_text}%"))
                                else
                                  paragraphs
                                end
      end

      def paragraphs
        @paragraphs ||= Decidim.find_resource_manifest(:paragraphs).try(:resource_scope, component)
                       &.published
                       &.order(id: :asc)
      end

      def paragraphs_collection_name
        Decidim::EnhancedTextwork::Paragraph.model_name.human(count: 2)
      end
    end
  end
end
