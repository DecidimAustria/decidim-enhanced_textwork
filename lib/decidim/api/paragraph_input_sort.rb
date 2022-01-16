# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class ParagraphInputSort < Decidim::Core::BaseInputSort
      include Decidim::Core::HasPublishableInputSort
      include Decidim::Core::HasEndorsableInputSort

      graphql_name "ParagraphSort"
      description "A type used for sorting paragraphs"

      argument :id, GraphQL::Types::String, "Sort by ID, valid values are ASC or DESC", required: false
      argument :vote_count,
               type: GraphQL::Types::String,
               description: "Sort by number of votes, valid values are ASC or DESC. Will be ignored if votes are hidden",
               required: false,
               as: :paragraph_votes_count
    end
  end
end
