# frozen_string_literal: true

Decidim.register_component(:textwork) do |component|
  component.engine = Decidim::EnhancedTextwork::Engine
  component.admin_engine = Decidim::EnhancedTextwork::AdminEngine
  component.icon_key = "draft-line"
  component.permissions_class_name = "Decidim::EnhancedTextwork::Permissions"
  component.actions = %w(support amend comment vote_comment)
  component.settings(:global) do |settings|
    settings.attribute :announcement, type: :text, translated: true, editor: true
    settings.attribute :comments_enabled, type: :boolean, default: true
    settings.attribute :comments_max_length, type: :integer, default: 1000
    settings.attribute :amendments_enabled, type: :boolean, default: true
    settings.attribute :textwork_hide_numbered_titles, type: :boolean, default: true
    settings.attribute :resources_permissions_enabled, type: :boolean, default: true
  end
  component.settings(:step) do |settings|
    settings.attribute :announcement, type: :text, translated: true, editor: true
    settings.attribute :comments_blocked, type: :boolean, default: false
    settings.attribute :supports_enabled, type: :boolean, default: true
    settings.attribute :supports_blocked, type: :boolean, default: false
    settings.attribute :amendment_creation_enabled, type: :boolean, default: true
  end
  %w(section amendment).each do |name|
    component.register_resource(name.to_sym) do |resource|
      resource.model_class_name = "Decidim::EnhancedTextwork::#{name.camelize}"
      resource.actions = %w(support amend comment vote_comment)
    end
  end
end
