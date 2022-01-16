# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # This class contains helpers needed to get rankings for a given paragraph
      # ordered by some given criteria.
      #
      module ParagraphRankingsHelper
        # Public: Gets the ranking for a given paragraph, ordered by some given
        # criteria. Paragraph is sorted amongst its own siblings.
        #
        # Returns a Hash with two keys:
        #   :ranking - an Integer representing the ranking for the given paragraph.
        #     Ranking starts with 1.
        #   :total - an Integer representing the total number of ranked paragraphs.
        #
        # Examples:
        #   ranking_for(paragraph, paragraph_votes_count: :desc)
        #   ranking_for(paragraph, endorsements_count: :desc)
        def ranking_for(paragraph, order = {})
          siblings = Decidim::EnhancedTextwork::Paragraph.where(component: paragraph.component)
          ranked = siblings.order([order, { id: :asc }])
          ranked_ids = ranked.pluck(:id)

          { ranking: ranked_ids.index(paragraph.id) + 1, total: ranked_ids.count }
        end

        # Public: Gets the ranking for a given paragraph, ordered by endorsements.
        def endorsements_ranking_for(paragraph)
          ranking_for(paragraph, endorsements_count: :desc)
        end

        # Public: Gets the ranking for a given paragraph, ordered by votes.
        def votes_ranking_for(paragraph)
          ranking_for(paragraph, paragraph_votes_count: :desc)
        end

        def i18n_endorsements_ranking_for(paragraph)
          rankings = endorsements_ranking_for(paragraph)

          I18n.t(
            "ranking",
            scope: "decidim.enhanced_textwork.admin.paragraphs.show",
            ranking: rankings[:ranking],
            total: rankings[:total]
          )
        end

        def i18n_votes_ranking_for(paragraph)
          rankings = votes_ranking_for(paragraph)

          I18n.t(
            "ranking",
            scope: "decidim.enhanced_textwork.admin.paragraphs.show",
            ranking: rankings[:ranking],
            total: rankings[:total]
          )
        end
      end
    end
  end
end
