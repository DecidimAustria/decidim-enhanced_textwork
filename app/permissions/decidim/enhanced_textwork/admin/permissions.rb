# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      class Permissions < Decidim::DefaultPermissions
        def permissions
          # The public part needs to be implemented yet
          return permission_action if permission_action.scope != :admin

          # Valuators can only perform these actions
          if user_is_valuator?
            if valuator_assigned_to_paragraph?
              can_create_paragraph_note?
              can_create_paragraph_answer?
            end
            can_export_paragraphs?
            valuator_can_unassign_valuator_from_paragraphs?

            return permission_action
          end

          if create_permission_action?
            can_create_paragraph_note?
            can_create_paragraph_from_admin?
            can_create_paragraph_answer?
          end

          # Admins can only edit official paragraphs if they are within the
          # time limit.
          allow! if permission_action.subject == :paragraph && permission_action.action == :edit && admin_edition_is_available?

          # Every user allowed by the space can update the category of the paragraph
          allow! if permission_action.subject == :paragraph_category && permission_action.action == :update

          # Every user allowed by the space can update the scope of the paragraph
          allow! if permission_action.subject == :paragraph_scope && permission_action.action == :update

          # Every user allowed by the space can import paragraphs from another_component
          allow! if permission_action.subject == :paragraphs && permission_action.action == :import

          # Every user allowed by the space can export paragraphs
          can_export_paragraphs?

          # Every user allowed by the space can merge paragraphs to another component
          allow! if permission_action.subject == :paragraphs && permission_action.action == :merge

          # Every user allowed by the space can split paragraphs to another component
          allow! if permission_action.subject == :paragraphs && permission_action.action == :split

          # Every user allowed by the space can assign paragraphs to a valuator
          allow! if permission_action.subject == :paragraphs && permission_action.action == :assign_to_valuator

          # Every user allowed by the space can unassign a valuator from paragraphs
          can_unassign_valuator_from_paragraphs?

          # Only admin users can publish many answers at once
          toggle_allow(user.admin?) if permission_action.subject == :paragraphs && permission_action.action == :publish_answers

          if permission_action.subject == :participatory_texts && participatory_texts_are_enabled? && permission_action.action == :manage
            # Every user allowed by the space can manage (import, update and publish) participatory texts to paragraphs
            allow!
          end

          permission_action
        end

        private

        def paragraph
          @paragraph ||= context.fetch(:paragraph, nil)
        end

        def user_valuator_role
          @user_valuator_role ||= space.user_roles(:valuator).find_by(user: user)
        end

        def user_is_valuator?
          return if user.admin?

          user_valuator_role.present?
        end

        def valuator_assigned_to_paragraph?
          @valuator_assigned_to_paragraph ||=
            Decidim::EnhancedTextwork::ValuationAssignment
            .where(paragraph: paragraph, valuator_role: user_valuator_role)
            .any?
        end

        def admin_creation_is_enabled?
          current_settings.try(:creation_enabled?) &&
            component_settings.try(:official_paragraphs_enabled)
        end

        def admin_edition_is_available?
          return unless paragraph

          (paragraph.official? || paragraph.official_meeting?) && paragraph.votes.empty?
        end

        def admin_paragraph_answering_is_enabled?
          current_settings.try(:paragraph_answering_enabled) &&
            component_settings.try(:paragraph_answering_enabled)
        end

        def create_permission_action?
          permission_action.action == :create
        end

        def participatory_texts_are_enabled?
          component_settings.participatory_texts_enabled?
        end

        # There's no special condition to create paragraph notes, only
        # users with access to the admin section can do it.
        def can_create_paragraph_note?
          allow! if permission_action.subject == :paragraph_note
        end

        # Paragraphs can only be created from the admin when the
        # corresponding setting is enabled.
        def can_create_paragraph_from_admin?
          toggle_allow(admin_creation_is_enabled?) if permission_action.subject == :paragraph
        end

        # Paragraphs can only be answered from the admin when the
        # corresponding setting is enabled.
        def can_create_paragraph_answer?
          toggle_allow(admin_paragraph_answering_is_enabled?) if permission_action.subject == :paragraph_answer
        end

        def can_unassign_valuator_from_paragraphs?
          allow! if permission_action.subject == :paragraphs && permission_action.action == :unassign_from_valuator
        end

        def valuator_can_unassign_valuator_from_paragraphs?
          can_unassign_valuator_from_paragraphs? if user == context.fetch(:valuator, nil)
        end

        def can_export_paragraphs?
          allow! if permission_action.subject == :paragraphs && permission_action.action == :export
        end
      end
    end
  end
end
