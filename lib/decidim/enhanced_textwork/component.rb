# frozen_string_literal: true

Decidim.register_component(:textwork) do |component|
  component.engine = Decidim::EnhancedTextwork::Engine
  component.admin_engine = Decidim::EnhancedTextwork::AdminEngine
  component.icon_key = "draft-line"
  component.permissions_class_name = "Decidim::EnhancedTextwork::Permissions"
  component.actions = %w(like suggest comment vote_comment)
  component.settings(:global) do |settings|
    settings.attribute :announcement, type: :text, translated: true, editor: true
    settings.attribute :comments_enabled, type: :boolean, default: true
    settings.attribute :comments_max_length, type: :integer, default: 1000
    settings.attribute :likes_enabled, type: :boolean, default: true
    settings.attribute :resources_permissions_enabled, type: :boolean, default: true
    settings.attribute :evaluation_enabled, type: :boolean, default: false
  end
  component.settings(:step) do |settings|
    settings.attribute :likes_enabled, type: :boolean, default: true
    settings.attribute :announcement, type: :text, translated: true, editor: true
    settings.attribute :comments_blocked, type: :boolean, default: false
    settings.attribute :likes_blocked, type: :boolean, default: false
    settings.attribute :suggestions_blocked, type: :boolean, default: false
  end
  component.on(:publish) do |instance|
    Decidim::EnhancedTextwork::Document.where(component: instance).find_in_batches(batch_size: 100) { |batch| Decidim::UpdateSearchIndexesJob.perform_later(batch) }
  end
  component.on(:unpublish) do |instance|
    Decidim::EnhancedTextwork::Document.where(component: instance).find_in_batches(batch_size: 100) { |batch| Decidim::RemoveSearchIndexesJob.perform_later(batch) }
  end
  %w(document block suggestion).each do |name|
    component.register_resource(name.to_sym) do |resource|
      resource.model_class_name = "Decidim::EnhancedTextwork::#{name.camelize}"
      if name == "document"
        resource.card = "decidim/enhanced_textwork/document"
        resource.searchable = true
      end
      resource.actions = %w(like suggest comment vote_comment)
    end
  end
end
