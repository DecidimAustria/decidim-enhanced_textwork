# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::EnhancedTextwork
      routes do
        root to: "documents#index"
        resources :documents, only: [:index, :show] do
          get :panel, on: :member
          get :statistics, on: :member
          get :history, on: :member
        end
        resources :blocks, only: [:index, :show] do
          resources :versions, only: [:index, :show]
          resources :suggestions, only: [:create, :update]
        end
        resources :suggestions, only: [:index, :show] do
          patch :withdraw, on: :member
        end
        match "interactions/:resource_type/:resource_id/:kind", to: "interactions#create", via: :post, as: :interaction
        match "interactions/:resource_type/:resource_id/:kind", to: "interactions#destroy", via: :delete
        get "textwork", to: "documents#index", as: :textwork
      end
      initializer "decidim_enhanced_textwork.assets" do
        Decidim.register_assets_path root.join("app/packs").to_s
      end
      initializer "decidim_enhanced_textwork.comment_visibility" do
        config.to_prepare do
          Decidim::Comments::Comment.prepend(CommentVisibility) unless Decidim::Comments::Comment < CommentVisibility
        end
      end
      initializer "decidim_enhanced_textwork.participation" do
        config.to_prepare do
          integrations = {
            Decidim::Permissions => CorePermissions::Global,
            Decidim::FollowsController => CoreFollowContext,
            Decidim::Comments::Permissions => CoreCommentPermissions,
            Decidim::LikeResource => CoreCommands::Like,
            Decidim::UnlikeResource => CoreCommands::Unlike,
            Decidim::CreateFollow => CoreCommands::Follow,
            Decidim::DeleteFollow => CoreCommands::Follow,
            Decidim::Comments::CreateComment => CoreCommands::CreateComment,
            Decidim::Comments::UpdateComment => CoreCommands::UpdateComment,
            Decidim::Comments::VoteComment => CoreCommands::VoteComment,
            Decidim::Comments::CommentsCell => CommentControls::List,
            Decidim::Comments::CommentFormCell => CommentControls::Form,
            Decidim::AuthorCell => CommentControls::Author,
            Decidim::Comments::CommentCell => CommentControls::Comment
          }
          integrations.each { |klass, extension| klass.prepend(extension) unless klass < extension }
        end
      end
      initializer "decidim_enhanced_textwork.icons" do
        %w(Document Block Suggestion).each do |name|
          Decidim.icons.register(name: "Decidim::EnhancedTextwork::#{name}", icon: "draft-line", description: "Textwork", category: "activity", engine: :core)
        end
      end
    end
  end
end
