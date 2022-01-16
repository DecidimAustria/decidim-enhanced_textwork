# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # This is the engine that runs on the public interface of `decidim-paragraphs`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::EnhancedTextwork::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        resources :paragraphs, only: [:show, :index, :new, :create, :edit, :update] do
          resources :valuation_assignments, only: [:destroy]
          collection do
            post :update_category
            post :publish_answers
            post :update_scope
            resource :paragraphs_import, only: [:new, :create]
            resource :paragraphs_merge, only: [:create]
            resource :paragraphs_split, only: [:create]
            resource :valuation_assignment, only: [:create, :destroy]
          end
          member do
            delete :destroy_draft
          end
          resources :paragraph_answers, only: [:edit, :update]
          resources :paragraph_notes, only: [:create]
        end

        resources :participatory_texts, only: [:index] do
          collection do
            get :new_editor
            get :new_import
            post :import
            patch :import
            post :import_from_editor
            patch :import_from_editor
            post :update
            post :discard
          end
        end

        root to: "paragraphs#index"
      end

      def load_seed
        nil
      end
    end
  end
end
