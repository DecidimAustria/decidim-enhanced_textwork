# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Metrics
      # Searches for Participants in the following actions
      #  - Create a paragraph (Paragraphs)
      #  - Give support to a paragraph (Paragraphs)
      #  - Endorse (Paragraphs)
      class ParagraphParticipantsMetricMeasure < Decidim::MetricMeasure
        def valid?
          super && @resource.is_a?(Decidim::Component)
        end

        def calculate
          cumulative_users = []
          cumulative_users |= retrieve_votes.pluck(:decidim_author_id)
          cumulative_users |= retrieve_endorsements.pluck(:decidim_author_id)
          cumulative_users |= retrieve_paragraphs.pluck("decidim_coauthorships.decidim_author_id") # To avoid ambiguosity must be called this way

          quantity_users = []
          quantity_users |= retrieve_votes(from_start: true).pluck(:decidim_author_id)
          quantity_users |= retrieve_endorsements(from_start: true).pluck(:decidim_author_id)
          quantity_users |= retrieve_paragraphs(from_start: true).pluck("decidim_coauthorships.decidim_author_id") # To avoid ambiguosity must be called this way

          {
            cumulative_users: cumulative_users.uniq,
            quantity_users: quantity_users.uniq
          }
        end

        private

        def retrieve_paragraphs(from_start: false)
          @paragraphs ||= Decidim::EnhancedTextwork::Paragraph.where(component: @resource).joins(:coauthorships)
                                                     .includes(:votes, :endorsements)
                                                     .where(decidim_coauthorships: {
                                                              decidim_author_type: [
                                                                "Decidim::UserBaseEntity",
                                                                "Decidim::Organization",
                                                                "Decidim::Meetings::Meeting"
                                                              ]
                                                            })
                                                     .where("decidim_enhanced_textwork_paragraphs.published_at <= ?", end_time)
                                                     .except_withdrawn

          return @paragraphs.where("decidim_enhanced_textwork_paragraphs.published_at >= ?", start_time) if from_start

          @paragraphs
        end

        def retrieve_votes(from_start: false)
          @votes ||= Decidim::EnhancedTextwork::ParagraphVote.joins(:paragraph).where(paragraph: retrieve_paragraphs).joins(:author)
                                                     .where("decidim_enhanced_textwork_paragraph_votes.created_at <= ?", end_time)

          return @votes.where("decidim_enhanced_textwork_paragraph_votes.created_at >= ?", start_time) if from_start

          @votes
        end

        def retrieve_endorsements(from_start: false)
          @endorsements ||= Decidim::Endorsement.joins("INNER JOIN decidim_enhanced_textwork_paragraphs paragraphs ON resource_id = paragraphs.id")
                                                .where(resource: retrieve_paragraphs)
                                                .where("decidim_endorsements.created_at <= ?", end_time)
                                                .where(decidim_author_type: "Decidim::UserBaseEntity")

          return @endorsements.where("decidim_endorsements.created_at >= ?", start_time) if from_start

          @endorsements
        end
      end
    end
  end
end
