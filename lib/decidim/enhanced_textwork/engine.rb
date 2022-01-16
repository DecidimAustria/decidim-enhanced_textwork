# frozen_string_literal: true

require "decidim/core"

module Decidim
  module EnhancedTextwork
    # This is the engine that runs on the public interface of `decidim-paragraphs`.
    # It mostly handles rendering the created page associated to a participatory
    # process.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::EnhancedTextwork

      routes do
        resources :paragraphs, except: [:destroy] do
          member do
            get :compare
            get :complete
            get :edit_draft
            patch :update_draft
            get :preview
            get :overview
            post :publish
            delete :destroy_draft
            put :withdraw
          end
          resource :paragraph_vote, only: [:create, :destroy]
          resource :widget, only: :show, path: "embed"
          resources :versions, only: [:show, :index]
        end
        resources :collaborative_drafts, except: [:destroy] do
          member do
            post :request_access, controller: "collaborative_draft_collaborator_requests"
            post :request_accept, controller: "collaborative_draft_collaborator_requests"
            post :request_reject, controller: "collaborative_draft_collaborator_requests"
            post :withdraw
            post :publish
          end
          resources :versions, only: [:show, :index]
        end
        root to: "paragraphs#index"
      end

      initializer "decidim.content_processors" do |_app|
        Decidim.configure do |config|
          config.content_processors += [:paragraph]
        end
      end

      initializer "decidim_enhanced_textwork.view_hooks" do
        Decidim.view_hooks.register(:participatory_space_highlighted_elements, priority: Decidim::ViewHooks::MEDIUM_PRIORITY) do |view_context|
          view_context.cell("decidim/enhanced_textwork/highlighted_paragraphs", view_context.current_participatory_space)
        end
      end

      initializer "decidim_changes" do
        config.to_prepare do
          Decidim::SettingsChange.subscribe "surveys" do |changes|
            Decidim::EnhancedTextwork::SettingsChangeJob.perform_later(
              changes[:component_id],
              changes[:previous_settings],
              changes[:current_settings]
            )
          end
        end
      end

      initializer "decidim_enhanced_textwork.mentions_listener" do
        config.to_prepare do
          Decidim::Comments::CommentCreation.subscribe do |data|
            paragraphs = data.dig(:metadatas, :paragraph).try(:linked_paragraphs)
            Decidim::EnhancedTextwork::NotifyParagraphsMentionedJob.perform_later(data[:comment_id], paragraphs) if paragraphs
          end
        end
      end

      # Subscribes to ActiveSupport::Notifications that may affect a Paragraph.
      initializer "decidim_enhanced_textwork.subscribe_to_events" do
        # when a paragraph is linked from a result
        event_name = "decidim.resourceable.included_paragraphs.created"
        ActiveSupport::Notifications.subscribe event_name do |_name, _started, _finished, _unique_id, data|
          payload = data[:this]
          if payload[:from_type] == Decidim::Accountability::Result.name && payload[:to_type] == Paragraph.name
            paragraph = Paragraph.find(payload[:to_id])
            paragraph.update(state: "accepted", state_published_at: Time.current)
          end
        end
      end

      initializer "decidim_enhanced_textwork.add_cells_view_paths" do
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::EnhancedTextwork::Engine.root}/app/cells")
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::EnhancedTextwork::Engine.root}/app/views") # for paragraph partials
      end

      initializer "decidim_enhanced_textwork.add_badges" do
        Decidim::Gamification.register_badge(:paragraphs) do |badge|
          badge.levels = [1, 5, 10, 30, 60]

          badge.valid_for = [:user, :user_group]

          badge.reset = lambda { |model|
            case model
            when User
              Decidim::Coauthorship.where(
                coauthorable_type: "Decidim::EnhancedTextwork::Paragraph",
                author: model,
                user_group: nil
              ).count
            when UserGroup
              Decidim::Coauthorship.where(
                coauthorable_type: "Decidim::EnhancedTextwork::Paragraph",
                user_group: model
              ).count
            end
          }
        end

        Decidim::Gamification.register_badge(:accepted_paragraphs) do |badge|
          badge.levels = [1, 5, 15, 30, 50]

          badge.valid_for = [:user, :user_group]

          badge.reset = lambda { |model|
            paragraph_ids = case model
                           when User
                             Decidim::Coauthorship.where(
                               coauthorable_type: "Decidim::EnhancedTextwork::Paragraph",
                               author: model,
                               user_group: nil
                             ).select(:coauthorable_id)
                           when UserGroup
                             Decidim::Coauthorship.where(
                               coauthorable_type: "Decidim::EnhancedTextwork::Paragraph",
                               user_group: model
                             ).select(:coauthorable_id)
                           end

            Decidim::EnhancedTextwork::Paragraph.where(id: paragraph_ids).accepted.count
          }
        end

        Decidim::Gamification.register_badge(:paragraph_votes) do |badge|
          badge.levels = [5, 15, 50, 100, 500]

          badge.reset = lambda { |user|
            Decidim::EnhancedTextwork::ParagraphVote.where(author: user).select(:decidim_paragraph_id).distinct.count
          }
        end
      end

      initializer "decidim_enhanced_textwork.register_metrics" do
        Decidim.metrics_registry.register(:paragraphs) do |metric_registry|
          metric_registry.manager_class = "Decidim::EnhancedTextwork::Metrics::ParagraphsMetricManage"

          metric_registry.settings do |settings|
            settings.attribute :highlighted, type: :boolean, default: true
            settings.attribute :scopes, type: :array, default: %w(home participatory_process)
            settings.attribute :weight, type: :integer, default: 2
            settings.attribute :stat_block, type: :string, default: "medium"
          end
        end

        Decidim.metrics_registry.register(:accepted_paragraphs) do |metric_registry|
          metric_registry.manager_class = "Decidim::EnhancedTextwork::Metrics::AcceptedParagraphsMetricManage"

          metric_registry.settings do |settings|
            settings.attribute :highlighted, type: :boolean, default: false
            settings.attribute :scopes, type: :array, default: %w(home participatory_process)
            settings.attribute :weight, type: :integer, default: 3
            settings.attribute :stat_block, type: :string, default: "small"
          end
        end

        Decidim.metrics_registry.register(:enhanced_textwork_votes) do |metric_registry|
          metric_registry.manager_class = "Decidim::EnhancedTextwork::Metrics::VotesMetricManage"

          metric_registry.settings do |settings|
            settings.attribute :highlighted, type: :boolean, default: true
            settings.attribute :scopes, type: :array, default: %w(home participatory_process)
            settings.attribute :weight, type: :integer, default: 3
            settings.attribute :stat_block, type: :string, default: "medium"
          end
        end

        Decidim.metrics_registry.register(:enhanced_textwork_endorsements) do |metric_registry|
          metric_registry.manager_class = "Decidim::EnhancedTextwork::Metrics::EndorsementsMetricManage"

          metric_registry.settings do |settings|
            settings.attribute :highlighted, type: :boolean, default: false
            settings.attribute :scopes, type: :array, default: %w(participatory_process)
            settings.attribute :weight, type: :integer, default: 4
            settings.attribute :stat_block, type: :string, default: "medium"
          end
        end

        Decidim.metrics_operation.register(:participants, :paragraphs) do |metric_operation|
          metric_operation.manager_class = "Decidim::EnhancedTextwork::Metrics::ParagraphParticipantsMetricMeasure"
        end
        Decidim.metrics_operation.register(:followers, :paragraphs) do |metric_operation|
          metric_operation.manager_class = "Decidim::EnhancedTextwork::Metrics::ParagraphFollowersMetricMeasure"
        end
      end
    end
  end
end
