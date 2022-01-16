# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class ParagraphListHelper < Decidim::Core::ComponentListBase
      # only querying published posts
      def query_scope
        super.published
      end
    end

    class ParagraphFinderHelper < Decidim::Core::ComponentFinderBase
      # only querying published posts
      def query_scope
        super.published
      end
    end

    class ParagraphsType < Decidim::Api::Types::BaseObject
      implements Decidim::Core::ComponentInterface

      graphql_name "Paragraphs"
      description "A paragraphs component of a participatory space."

      field :paragraphs, type: Decidim::EnhancedTextwork::ParagraphType.connection_type, description: "List all paragraphs", connection: true, null: true do
        argument :order, Decidim::EnhancedTextwork::ParagraphInputSort, "Provides several methods to order the results", required: false
        argument :filter, Decidim::EnhancedTextwork::ParagraphInputFilter, "Provides several methods to filter the results", required: false
      end

      field :paragraph, type: Decidim::EnhancedTextwork::ParagraphType, description: "Finds one paragraph", null: true do
        argument :id, GraphQL::Types::ID, "The ID of the paragraph", required: true
      end

      def paragraphs(filter: {}, order: {})
        Decidim::EnhancedTextwork::ParagraphListHelper.new(model_class: Paragraph).call(object, { filter: filter, order: order }, context)
      end

      def paragraph(id:)
        Decidim::EnhancedTextwork::ParagraphFinderHelper.new(model_class: Paragraph).call(object, { id: id }, context)
      end
    end
  end
end
