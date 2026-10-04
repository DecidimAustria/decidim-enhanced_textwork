# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      class SectionsController < ApplicationController
        def edit
          @section = document.sections.find(params[:id])
          @form = form(ContentForm).from_params(title: helpers.translated_attribute(@section.title), body: helpers.translated_attribute(@section.body),
                                                base_revision_id: @section.current_revision_id)
        end

        def update
          @form = form(ContentForm).from_params(params)
          document.with_lock do
            @section = document.sections.find(params[:id])
            return head :conflict unless @section.current_revision_id == @form.base_revision_id

            body = Decidim::ContentProcessor.sanitize(@form.body)
            if !@form.valid? || Nokogiri::HTML.fragment(body).text.strip.blank? || @form.title.blank?
              return render :edit, status: :unprocessable_content
            end

            revision = @section.revisions.create!(number: @section.revisions.maximum(:number) + 1, author: current_user,
                                                  title: @section.title.merge(I18n.locale.to_s => @form.title), body: @section.body.merge(I18n.locale.to_s => body))
            @section.update!(current_revision: revision)
            document.snapshot!(current_user) if document.published?
          end
          redirect_to textwork_path
        end

        def destroy
          document.with_lock do
            return head :conflict if document.published?

            section = document.sections.find(params[:id])
            section.update!(current_revision: nil)
            section.revisions.delete_all
            section.destroy!
          end
          redirect_to textwork_path
        end

        def move
          document.with_lock do
            section = document.sections.find(params[:id])
            list = document.sections.to_a
            index = list.index(section)
            offset = params[:direction] == "up" ? -1 : 1
            other = index + offset
            if other >= 0 && other < list.size
              list[index], list[other] = list[other], list[index]
              list.each_with_index { |item, i| item.update!(position: i + 1) }
              document.snapshot!(current_user) if document.published?
            end
          end
          redirect_to textwork_path
        end
      end
    end
  end
end
