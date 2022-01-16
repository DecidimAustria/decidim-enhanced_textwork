# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # This class is responsible for creating the imported paragraphs
    # and must be included in paragraphs component's import manifest.
    class ParagraphCreator < Decidim::Admin::Import::Creator
      # Retuns the resource class to be created with the provided data.
      def self.resource_klass
        Decidim::EnhancedTextwork::Paragraph
      end

      # Produces a paragraph from parsed data
      #
      # Returns a paragraph
      def produce
        resource.add_coauthor(context[:current_user], user_group: context[:user_group])

        resource
      end

      # Saves the paragraph
      def finish!
        super # resource.save!
        notify(resource)
        publish(resource)
      end

      private

      attr_reader :context

      def resource
        @resource ||= Decidim::EnhancedTextwork::Paragraph.new(
          category: category,
          scope: scope,
          title: title,
          body: body,
          component: component,
          published_at: Time.current
        )
      end

      def category
        id = data.has_key?(:category) ? data[:category]["id"] : data[:"category/id"].to_i
        Decidim::Category.find_by(id: id)
      end

      def scope
        id = data.has_key?(:scope) ? data[:scope]["id"] : data[:"scope/id"].to_i
        Decidim::Scope.find_by(id: id)
      end

      def title
        locale_hasher("title", available_locales)
      end

      def body
        locale_hasher("body", available_locales)
      end

      def available_locales
        @available_locales ||= component.participatory_space.organization.available_locales
      end

      def component
        context[:current_component]
      end

      def notify(paragraph)
        return if paragraph.coauthorships.empty?

        Decidim::EventsManager.publish(
          event: "decidim.events.enhanced_textwork.paragraph_published",
          event_class: Decidim::EnhancedTextwork::PublishParagraphEvent,
          resource: paragraph,
          followers: coauthors_followers(paragraph)
        )
      end

      def publish(paragraph)
        Decidim::EventsManager.publish(
          event: "decidim.events.enhanced_textwork.paragraph_published",
          event_class: Decidim::EnhancedTextwork::PublishParagraphEvent,
          resource: paragraph,
          followers: paragraph.participatory_space.followers - coauthors_followers(paragraph),
          extra: {
            participatory_space: true
          }
        )
      end

      def coauthors_followers(paragraph)
        @coauthors_followers ||= paragraph.authors.flat_map(&:followers)
      end
    end
  end
end
