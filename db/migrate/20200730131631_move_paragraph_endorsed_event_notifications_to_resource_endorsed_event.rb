# frozen_string_literal: true

class MoveParagraphEndorsedEventNotificationsToResourceEndorsedEvent < ActiveRecord::Migration[5.2]
  def up
    Decidim::Notification.where(event_name: "decidim.events.enhanced_textwork.paragraph_endorsed", event_class: "Decidim::EnhancedTextwork::ParagraphEndorsedEvent").find_each do |notification|
      notification.update(event_name: "decidim.events.resource_endorsed", event_class: "Decidim::ResourceEndorsedEvent")
    end
  end

  def down
    Decidim::Notification.where(
      event_name: "decidim.events.resource_endorsed",
      event_class: "Decidim::ResourceEndorsedEvent",
      decidim_resource_type: "Decidim::EnhancedTextwork::Paragraph"
    )
                         .find_each do |notification|
      notification.update(event_name: "decidim.events.enhanced_textwork.paragraph_endorsed", event_class: "Decidim::EnhancedTextwork::ParagraphEndorsedEvent")
    end
  end
end
