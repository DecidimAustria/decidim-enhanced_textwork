# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    class AmendmentsController < ApplicationController
      before_action :authenticate_user!, except: [:show]
      def show
        @amendment = visible_amendments.find(params[:id])
      end

      def new
        @section = visible_sections.find(params[:section_id])
        authorize_creation!
        @amendment = @section.amendments.new(base_revision: @section.current_revision, title: @section.title, body: @section.body)
        @form = form(ContentForm).from_params(title: helpers.translated_attribute(@section.title), body: helpers.translated_attribute(@section.body),
                                              base_revision_id: @section.current_revision_id)
      end

      def create
        @section = visible_sections.find(params[:section_id])
        authorize_creation!
        @form = form(ContentForm).from_params(params)
        @section.document.with_lock do
          @section.reload
          base = @section.revisions.find(@form.base_revision_id)
          return head :conflict unless base.id == @section.current_revision_id

          body = @section.body.merge(I18n.locale.to_s => Decidim::ContentProcessor.sanitize(@form.body))
          title = @form.title.present? ? @section.title.merge(I18n.locale.to_s => @form.title) : @section.title
          @amendment = @section.amendments.new(component: current_component, author: current_user, base_revision: base,
                                               title:, body:, reason: @form.reason)
          if !@form.valid? || Nokogiri::HTML.fragment(body[I18n.locale.to_s]).text.strip.blank? || (body == base.body && title == base.title)
            @amendment.errors.add(:body, :invalid)
            render :new, status: :unprocessable_content
          elsif @amendment.save
            redirect_to amendment_path(@amendment)
          else
            render :new, status: :unprocessable_content
          end
        end
      end

      def withdraw
        amendment = visible_amendments.find(params[:id])
        raise Decidim::ActionForbidden unless amendment.author == current_user

        amendment.document.with_lock do
          amendment.reload
          return head :conflict unless amendment.state == "pending"

          amendment.update!(state: "withdrawn")
        end
        redirect_to amendment_path(amendment)
      end

      private

      def authorize_creation!
        ensure_allowed!(@section, :amend)
        raise Decidim::ActionForbidden unless component_settings.amendments_enabled? && current_settings.amendment_creation_enabled?
      end
    end
  end
end
