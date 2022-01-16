# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # This class contains helpers needed to format Meetings
      # in order to use them in select forms for Paragraphs.
      #
      module EnhancedTextworkHelper
        include Decidim::Admin::ResourceScopeHelper

        # Public: A formatted collection of Meetings to be used
        # in forms.
        def meetings_as_authors_selected
          return unless @paragraph.present? && @paragraph.official_meeting?

          @meetings_as_authors_selected ||= @paragraph.authors.pluck(:id)
        end

        def coauthor_presenters_for(paragraph)
          paragraph.authors.map do |identity|
            if identity.is_a?(Decidim::Organization)
              Decidim::EnhancedTextwork::OfficialAuthorPresenter.new
            else
              present(identity)
            end
          end
        end

        def endorsers_presenters_for(paragraph)
          paragraph.endorsements.for_listing.map { |identity| present(identity.normalized_author) }
        end

        def paragraph_complete_state(paragraph)
          return humanize_paragraph_state(paragraph.internal_state).html_safe if paragraph.answered? && !paragraph.published_state?

          humanize_paragraph_state(paragraph.state).html_safe
        end

        def paragraphs_admin_filter_tree
          {
            t("paragraphs.filters.type", scope: "decidim.enhanced_textwork") => {
              link_to(t("paragraphs", scope: "decidim.enhanced_textwork.application_helper.filter_type_values"), q: ransak_params_for_query(is_emendation_true: "0"),
                                                                                                        per_page: per_page) => nil,
              link_to(t("amendments", scope: "decidim.enhanced_textwork.application_helper.filter_type_values"), q: ransak_params_for_query(is_emendation_true: "1"),
                                                                                                         per_page: per_page) => nil
            },
            t("models.paragraph.fields.state", scope: "decidim.enhanced_textwork") =>
              Decidim::EnhancedTextwork::Paragraph::POSSIBLE_STATES.each_with_object({}) do |state, hash|
                if state == "not_answered"
                  hash[link_to((humanize_paragraph_state state), q: ransak_params_for_query(state_null: 1), per_page: per_page)] = nil
                else
                  hash[link_to((humanize_paragraph_state state), q: ransak_params_for_query(state_eq: state), per_page: per_page)] = nil
                end
              end,
            t("models.paragraph.fields.category", scope: "decidim.enhanced_textwork") => admin_filter_categories_tree(categories.first_class),
            t("paragraphs.filters.scope", scope: "decidim.enhanced_textwork") => admin_filter_scopes_tree(current_component.organization.id)
          }
        end

        def paragraphs_admin_search_hidden_params
          return unless params[:q]

          tags = ""
          tags += hidden_field_tag "per_page", params[:per_page] if params[:per_page]
          tags += hidden_field_tag "q[is_emendation_true]", params[:q][:is_emendation_true] if params[:q][:is_emendation_true]
          tags += hidden_field_tag "q[state_eq]", params[:q][:state_eq] if params[:q][:state_eq]
          tags += hidden_field_tag "q[category_id_eq]", params[:q][:category_id_eq] if params[:q][:category_id_eq]
          tags += hidden_field_tag "q[scope_id_eq]", params[:q][:scope_id_eq] if params[:q][:scope_id_eq]
          tags.html_safe
        end

        def paragraphs_admin_filter_applied_filters
          html = []
          if params[:q][:is_emendation_true].present?
            html << tag.span(class: "label secondary") do
              tag = "#{t("filters.type", scope: "decidim.enhanced_textwork.paragraphs")}: "
              tag += if params[:q][:is_emendation_true].to_s == "1"
                       t("amendments", scope: "decidim.enhanced_textwork.application_helper.filter_type_values")
                     else
                       t("paragraphs", scope: "decidim.enhanced_textwork.application_helper.filter_type_values")
                     end
              tag += icon_link_to("circle-x", url_for(q: ransak_params_for_query_without(:is_emendation_true), per_page: per_page), t("decidim.admin.actions.cancel"),
                                  class: "action-icon--remove")
              tag.html_safe
            end
          end
          if params[:q][:state_null]
            html << tag.span(class: "label secondary") do
              tag = "#{t("models.paragraph.fields.state", scope: "decidim.enhanced_textwork")}: "
              tag += humanize_paragraph_state "not_answered"
              tag += icon_link_to("circle-x", url_for(q: ransak_params_for_query_without(:state_null), per_page: per_page), t("decidim.admin.actions.cancel"),
                                  class: "action-icon--remove")
              tag.html_safe
            end
          end
          if params[:q][:state_eq]
            html << tag.span(class: "label secondary") do
              tag = "#{t("models.paragraph.fields.state", scope: "decidim.enhanced_textwork")}: "
              tag += humanize_paragraph_state params[:q][:state_eq]
              tag += icon_link_to("circle-x", url_for(q: ransak_params_for_query_without(:state_eq), per_page: per_page), t("decidim.admin.actions.cancel"),
                                  class: "action-icon--remove")
              tag.html_safe
            end
          end
          if params[:q][:category_id_eq]
            html << tag.span(class: "label secondary") do
              tag = "#{t("models.paragraph.fields.category", scope: "decidim.enhanced_textwork")}: "
              tag += translated_attribute categories.find(params[:q][:category_id_eq]).name
              tag += icon_link_to("circle-x", url_for(q: ransak_params_for_query_without(:category_id_eq), per_page: per_page), t("decidim.admin.actions.cancel"),
                                  class: "action-icon--remove")
              tag.html_safe
            end
          end
          if params[:q][:scope_id_eq]
            html << tag.span(class: "label secondary") do
              tag = "#{t("models.paragraph.fields.scope", scope: "decidim.enhanced_textwork")}: "
              tag += translated_attribute Decidim::Scope.where(decidim_organization_id: current_component.organization.id).find(params[:q][:scope_id_eq]).name
              tag += icon_link_to("circle-x", url_for(q: ransak_params_for_query_without(:scope_id_eq), per_page: per_page), t("decidim.admin.actions.cancel"),
                                  class: "action-icon--remove")
              tag.html_safe
            end
          end
          html.join(" ").html_safe
        end

        def icon_with_link_to_paragraph(paragraph)
          icon, tooltip = if allowed_to?(:create, :paragraph_answer, paragraph: paragraph) && !paragraph.emendation?
                            [
                              "comment-square",
                              t(:answer_paragraph, scope: "decidim.enhanced_textwork.actions")
                            ]
                          else
                            [
                              "info",
                              t(:show, scope: "decidim.enhanced_textwork.actions")
                            ]
                          end
          icon_link_to(icon, paragraph_path(paragraph), tooltip, class: "icon--small action-icon--show-paragraph")
        end
      end
    end
  end
end
