# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class SupportsController < ApplicationController
      before_action :authenticate_user!
      def create
        change_support(remove: false)
      end

      def destroy
        change_support(remove: true)
      end

      private

      def change_support(remove:)
        resource = params[:amendment_id] ? visible_amendments.find(params[:amendment_id]) : visible_sections.find(params[:section_id])
        ensure_allowed!(resource, :support)
        raise Decidim::ActionForbidden unless current_settings.supports_enabled? && !current_settings.supports_blocked?

        resource.document.with_lock do
          resource.reload
          target = if resource.is_a?(Section)
                     revision = resource.revisions.find(params.require(:revision_id))
                     return head :conflict if !remove && revision.id != resource.current_revision_id

                     revision
                   else
                     return head :conflict if !remove && resource.state != "pending"

                     resource
                   end
          if remove
            target.supports.where(author: current_user).destroy_all
          else
            target.supports.find_or_create_by!(author: current_user)
          end
        end
        redirect_to(resource.is_a?(Section) ? textwork_path(paragraph_id: resource.id) : amendment_path(resource))
      end
    end
  end
end
