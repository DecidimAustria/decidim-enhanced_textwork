# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin; end

    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::EnhancedTextwork::Admin
      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil
      routes do
        root to: "texts#show"
        get "textwork", to: "texts#show", as: :textwork
        post "textwork/import", to: "texts#import", as: :import_textwork
        patch "textwork/publish", to: "texts#publish", as: :publish_textwork
        get "textwork/export", to: "texts#export", as: :export_textwork
        resources :sections, only: [:edit, :update, :destroy] do
          patch :move, on: :member
        end
        resources :amendments, only: [] do
          patch :decide, on: :member
        end
      end
      def load_seed; end
    end
  end
end
