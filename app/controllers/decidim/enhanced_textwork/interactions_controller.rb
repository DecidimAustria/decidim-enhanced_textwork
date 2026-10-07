# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class InteractionsController < ApplicationController
      before_action :authenticate_user!

      def create = interact(true)

      def destroy = interact(false)

      private

      def interaction_resource
        resource = case params[:resource_type]
                   when "block" then published_document.blocks.active.find(params[:resource_id])
                   when "suggestion" then Suggestion.listed.where(block: published_document.blocks.active).find(params[:resource_id])
                   when "document" then published_document
                   else raise ActiveRecord::RecordNotFound
                   end
        raise ActiveRecord::RecordNotFound unless resource.id.to_s == params[:resource_id]

        resource
      end

      def interact(add)
        resource = interaction_resource
        raise ActiveRecord::RecordNotFound unless %w(like follow).include?(params[:kind])

        ensure_allowed!(resource, params[:kind].to_sym)
        resource.document.with_lock do
          resource.reload
          params[:kind] == "like" ? toggle_like(resource, add) : toggle_follow(resource, add)
        end
        render json: { key: "#{params[:resource_type]}-#{resource.id}",
                       liked: resource.liked_by?(current_user), likes: resource.reload.likes_count,
                       likes_label: I18n.t("decidim.textwork.suggestions.likes_count", count: resource.likes_count),
                       followed: resource.respond_to?(:follows) && Decidim::Follow.exists?(followable: resource, user: current_user) }
      end

      def toggle_like(resource, add)
        raise Decidim::ActionForbidden unless Participation.like_allowed?(current_user, resource, add:)
        return if resource.liked_by?(current_user) == add

        command = add ? Decidim::LikeResource : Decidim::UnlikeResource
        command.call(resource, current_user) { on(:invalid) { raise Decidim::ActionForbidden } }
        return unless add && resource.is_a?(Suggestion) && resource.feedback_received_at.nil?

        # Participation metadata must not create another text version.
        resource.update_column(:feedback_received_at, Time.current) # rubocop:disable Rails/SkipsModelValidations
      end

      def toggle_follow(resource, add)
        raise Decidim::ActionForbidden unless resource.respond_to?(:followable?) && resource.followable?

        if add
          return if Decidim::Follow.exists?(followable: resource, user: current_user)

          follow_form = form(Decidim::FollowForm).from_params(followable_gid: resource.to_sgid.to_s)
          Decidim::CreateFollow.call(follow_form) { on(:invalid) { raise Decidim::ActionForbidden } }
        else
          Decidim::Follow.where(followable: resource, user: current_user).each(&:destroy!)
        end
      end
    end
  end
end
