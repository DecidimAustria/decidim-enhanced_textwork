# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # Custom helpers, scoped to the paragraphs engine.
    #
    module ApplicationHelper
      include Decidim::Comments::CommentsHelper
      include PaginateHelper
      include ParagraphVotesHelper
      include ::Decidim::EndorsableHelper
      include ::Decidim::FollowableHelper
      include Decidim::MapHelper
      include Decidim::EnhancedTextwork::MapHelper
      include CollaborativeDraftHelper
      include ControlVersionHelper
      include Decidim::RichTextEditorHelper
      include Decidim::CheckBoxesTreeHelper

      delegate :minimum_votes_per_user, to: :component_settings

      # Public: The state of a paragraph in a way a human can understand.
      #
      # state - The String state of the paragraph.
      #
      # Returns a String.
      def humanize_paragraph_state(state)
        I18n.t(state, scope: "decidim.enhanced_textwork.answers", default: :not_answered)
      end

      # Public: The css class applied based on the paragraph state.
      #
      # paragraph - The paragraph to evaluate.
      #
      # Returns a String.
      def paragraph_state_css_class(paragraph)
        state = paragraph.state
        state = paragraph.internal_state if paragraph.answered? && !paragraph.published_state?

        case state
        when "accepted"
          "text-success"
        when "rejected"
          "text-alert"
        when "evaluating"
          "text-warning"
        when "withdrawn"
          "text-alert"
        else
          "text-info"
        end
      end

      # Public: The state of a paragraph in a way a human can understand.
      #
      # state - The String state of the paragraph.
      #
      # Returns a String.
      def humanize_collaborative_draft_state(state)
        I18n.t("decidim.enhanced_textwork.collaborative_drafts.states.#{state}", default: :open)
      end

      # Public: The css class applied based on the collaborative draft state.
      #
      # state - The String state of the collaborative draft.
      #
      # Returns a String.
      def collaborative_draft_state_badge_css_class(state)
        case state
        when "open"
          "success"
        when "withdrawn"
          "alert"
        when "published"
          "secondary"
        end
      end

      def paragraph_limit_enabled?
        paragraph_limit.present?
      end

      def minimum_votes_per_user_enabled?
        minimum_votes_per_user.positive?
      end

      def not_from_collaborative_draft(paragraph)
        paragraph.linked_resources(:paragraphs, "created_from_collaborative_draft").empty?
      end

      def not_from_participatory_text(paragraph)
        paragraph.participatory_text_level.nil?
      end

      # If the paragraph is official or the rich text editor is enabled on the
      # frontend, the paragraph body is considered as safe content; that's unless
      # the paragraph comes from a collaborative_draft or a participatory_text.
      def safe_content?
        rich_text_editor_in_public_views? && not_from_collaborative_draft(@paragraph) ||
          (@paragraph.official? || @paragraph.official_meeting?) && not_from_participatory_text(@paragraph)
      end

      # If the content is safe, HTML tags are sanitized, otherwise, they are stripped.
      def render_paragraph_body(paragraph)
        body = present(paragraph).body(links: true, strip_tags: !safe_content?)
        body = simple_format(body, {}, sanitize: false)

        return body unless safe_content?

        decidim_sanitize(body)
      end

      # Returns :text_area or :editor based on the organization' settings.
      def text_editor_for_paragraph_body(form)
        options = {
          class: "js-hashtags",
          hashtaggable: true,
          value: form_presenter.body(extras: false).strip
        }

        text_editor_for(form, :body, options)
      end

      def paragraph_limit
        return if component_settings.paragraph_limit.zero?

        component_settings.paragraph_limit
      end

      def votes_given
        @votes_given ||= ParagraphVote.where(
          paragraph: Paragraph.where(component: current_component),
          author: current_user
        ).count
      end

      def votes_count_for(model, from_paragraphs_list)
        render partial: "decidim/enhanced_textwork/paragraphs/participatory_texts/paragraph_votes_count.html", locals: { paragraph: model, from_paragraphs_list: from_paragraphs_list }
      end

      def vote_button_for(model, from_paragraphs_list)
        render partial: "decidim/enhanced_textwork/paragraphs/participatory_texts/paragraph_vote_button.html", locals: { paragraph: model, from_paragraphs_list: from_paragraphs_list }
      end

      def form_has_address?
        @form.address.present? || @form.has_address
      end

      def show_voting_rules?
        return false unless votes_enabled?

        return true if vote_limit_enabled?
        return true if threshold_per_paragraph_enabled?
        return true if paragraph_limit_enabled?
        return true if can_accumulate_supports_beyond_threshold?
        return true if minimum_votes_per_user_enabled?
      end

      def filter_type_values
        [
          ["all", t("decidim.enhanced_textwork.application_helper.filter_type_values.all")],
          ["paragraphs", t("decidim.enhanced_textwork.application_helper.filter_type_values.paragraphs")],
          ["amendments", t("decidim.enhanced_textwork.application_helper.filter_type_values.amendments")]
        ]
      end

      # Options to filter Paragraphs by activity.
      def activity_filter_values
        base = [
          ["all", t(".all")],
          ["my_paragraphs", t(".my_paragraphs")]
        ]
        base += [["voted", t(".voted")]] if current_settings.votes_enabled?
        base
      end

      def filter_origin_values
        origin_values = []
        origin_values << TreePoint.new("official", t("decidim.enhanced_textwork.application_helper.filter_origin_values.official")) if component_settings.official_paragraphs_enabled
        origin_values << TreePoint.new("citizens", t("decidim.enhanced_textwork.application_helper.filter_origin_values.citizens"))
        origin_values << TreePoint.new("user_group", t("decidim.enhanced_textwork.application_helper.filter_origin_values.user_groups")) if current_organization.user_groups_enabled?
        origin_values << TreePoint.new("meeting", t("decidim.enhanced_textwork.application_helper.filter_origin_values.meetings"))

        TreeNode.new(
          TreePoint.new("", t("decidim.enhanced_textwork.application_helper.filter_origin_values.all")),
          origin_values
        )
      end
    end
  end
end
