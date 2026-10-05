# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin; end

    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::EnhancedTextwork::Admin
      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil
      routes do
        root to: "documents#show"
        get "textwork", to: "documents#show", as: :textwork
        delete "documents", to: "documents#trash", as: :trash_document
        patch "documents/restore", to: "documents#restore", as: :restore_document
        post "documents", to: "documents#create", as: :create_document
        patch "documents", to: "documents#update", as: :update_document
        patch "documents/publish", to: "documents#publish", as: :publish_document
        get "documents/export", to: "documents#export", as: :export_document
        get "documents", to: "documents#show"
        post "blocks", to: "documents#add", as: :add_block
        get "blocks/:block_id/edit", to: "documents#edit_block", as: :edit_block
        patch "blocks/:block_id", to: "documents#update_block", as: :update_block
        delete "blocks/:block_id", to: "documents#remove", as: :remove_block
        patch "blocks/:block_id/move", to: "documents#move", as: :move_block
        get "suggestions/:suggestion_id", to: "documents#suggestion", as: :review_suggestion
        patch "suggestions/:suggestion_id", to: "documents#decide", as: :decide_suggestion
      end
      def load_seed; end
    end
  end
end
