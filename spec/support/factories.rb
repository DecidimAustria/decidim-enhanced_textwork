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
end
