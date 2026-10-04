# frozen_string_literal: true

FactoryBot.define do
  factory :textwork_component, parent: :component do
    manifest_name { :textwork }
  end
  factory :textwork_document, class: "Decidim::EnhancedTextwork::Document" do
    component { association(:textwork_component, :published) }
    title { { en: "Community plan" } }
    description { { en: "A participatory document" } }
    published_at { Time.current }
  end
  factory :textwork_section, class: "Decidim::EnhancedTextwork::Section" do
    document { association(:textwork_document) }
    component { document.component }
    sequence(:position)
    level { "article" }
    after(:create) do |section|
      author = FactoryBot.create(:user, :confirmed, organization: section.organization)
      revision = section.revisions.create!(author:, number: 1, title: { en: section.position.to_s }, body: { en: "More trees and places to sit." })
      section.update!(current_revision: revision)
    end
  end
  factory :textwork_amendment, class: "Decidim::EnhancedTextwork::Amendment" do
    section { association(:textwork_section) }
    component { section.component }
    base_revision { section.current_revision }
    author { association(:user, :confirmed, organization: section.organization) }
    title { { en: "Suggested revision" } }
    body { { en: "Trees and shaded benches." } }
  end
end
