# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::EnhancedTextwork

      initializer "decidim_enhanced_textwork.settings" do
        Decidim.find_component_manifest(:proposals).settings(:global) do |settings|
          settings.attribute :enhanced_textwork_enabled, type: :boolean, default: false
          settings.attribute :textwork_hide_numbered_titles, type: :boolean, default: true
        end
      end

      initializer "decidim_enhanced_textwork.routes" do
        Decidim::Proposals::Engine.routes.append do
          get "textwork", to: "/decidim/enhanced_textwork/texts#show", as: :textwork
        end

        Decidim::Proposals::AdminEngine.routes.append do
          get "textwork", to: "/decidim/enhanced_textwork/admin/texts#show", as: :textwork
          post "textwork/import", to: "/decidim/enhanced_textwork/admin/texts#import", as: :import_textwork
          get "textwork/export", to: "/decidim/enhanced_textwork/admin/texts#export", as: :export_textwork
          delete "textwork/drafts/:id", to: "/decidim/enhanced_textwork/admin/texts#destroy_draft", as: :textwork_draft
        end
      end

      initializer "decidim_enhanced_textwork.assets" do
        Decidim.register_assets_path root.join("app/packs").to_s
      end

      config.to_prepare do
        Decidim::Proposals::ProposalsController.prepend(Decidim::EnhancedTextwork::ProposalsControllerExtension)
      end
    end
  end
end
