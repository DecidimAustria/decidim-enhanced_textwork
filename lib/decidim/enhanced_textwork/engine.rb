# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::EnhancedTextwork
      routes do
        root to: "texts#show"
        get "textwork", to: "texts#show", as: :textwork
        resources :sections, only: [:show] do
          resource :support, only: [:create, :destroy]
          resources :amendments, only: [:new, :create]
        end
        resources :amendments, only: [:show] do
          resource :support, only: [:create, :destroy]
          patch :withdraw, on: :member
        end
      end
      initializer "decidim_enhanced_textwork.assets" do
        Decidim.register_assets_path root.join("app/packs").to_s
      end
      initializer "decidim_enhanced_textwork.icons" do
        %w(Section Amendment).each do |name|
          Decidim.icons.register(name: "Decidim::EnhancedTextwork::#{name}", icon: "draft-line", description: "Textwork", category: "activity", engine: :core)
        end
      end
    end
  end
end
