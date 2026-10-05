# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      class DocumentsController < ApplicationController
        helper Decidim::EnhancedTextwork::ReadingHelper
        rescue_from ReadingExport::MissingTranslation, with: -> { redirect_to textwork_path, alert: t("decidim.textwork.export_missing_translation") }
        rescue_from EditDocument::Conflict, with: -> { redirect_to textwork_path, alert: t("decidim.textwork.conflict") }
        rescue_from EditDocument::Invalid, ActiveRecord::RecordInvalid, with: -> { redirect_to textwork_path, alert: t("decidim.textwork.invalid") }

        def show
          @document = Document.with_deleted.find_by(component: current_component)
          @form = form(ImportForm).from_params(locale: current_organization.default_locale)
          @blocks = @document ? @document.blocks.active.ordered : Block.none
          @suggestions = @document ? Suggestion.where(block: @document.blocks).where(status: "pending").not_hidden.order(:created_at) : Suggestion.none
        end

        def create
          @form = form(ImportForm).from_params(params)
          unless @form.valid? && @form.title.to_h[@form.locale].present?
            @blocks = Block.none
            @suggestions = Suggestion.none
            return render :show, status: :unprocessable_content
          end
          current_component.with_lock do
            html = @form.document.present? ? DocumentInput.read(@form.document) : @form.content
            blocks = Markdown.from_html(html)
            raise EditDocument::Invalid if blocks.empty?

            @document = Document.create!(component: current_component, locale: @form.locale, title: @form.title, description: @form.description)
            editor = EditDocument.new(@document, current_user)
            blocks.each { |block| editor.add(**block, origin: "import") }
            @document.document_revisions.create!(number: @document.document_revisions.maximum(:number).to_i + 1, kind: "import", author: current_user,
                                                 details: { blocks: @document.blocks.active.ordered.pluck(:id) })
          end
          redirect_to textwork_path, notice: t("decidim.textwork.imported")
        rescue DocumentInput::Invalid
          redirect_to textwork_path, alert: t("decidim.textwork.invalid_file")
        end

        def publish
          raise EditDocument::Invalid unless document.blocks.active.exists?

          document.published? ? document.unpublish! : document.publish!
          redirect_to textwork_path
        end

        def update
          document.with_lock do
            [:title, :description].each do |field|
              values = params.fetch(field, ActionController::Parameters.new).permit(*current_organization.available_locales).to_h
              source = values.fetch(document.locale, document.original(field))
              previous = document[field].dup
              changed_source = source != document.original(field)
              document.replace_original(field, source)
              translations = values.except(document.locale).reject { |locale, value| value.blank? || (changed_source && value == previous[locale]) }
              document[field] = document[field].merge(translations)
            end
            document.save!
          end
          redirect_to textwork_path, notice: t("decidim.textwork.saved")
        end

        def add
          EditDocument.new(document, current_user).add(body: params[:body].to_s, kind: params[:kind], depth: params[:depth].to_i, position: params[:position].presence)
          redirect_to textwork_path
        end

        def edit_block
          @block = document.blocks.active.find(params[:block_id])
        end

        def update_block
          block = document.blocks.active.find(params[:block_id])
          document.with_lock do
            previous = block.body.dup
            changed_source = block.original != params[:body].to_s
            EditDocument.new(document, current_user).update(block, body: params[:body].to_s, expected_version: params[:expected_version])
            translations = params.fetch(:translations, ActionController::Parameters.new).permit(*current_organization.available_locales).to_h.except(document.locale)
            translations.reject! { |locale, value| value.blank? || (changed_source && value == previous[locale] && Array(params[:reviewed]).exclude?(locale)) }
            block.update!(body: block.body.merge(translations)) if translations.any?
          end
          redirect_to textwork_path, notice: t("decidim.textwork.saved")
        end

        def remove
          EditDocument.new(document, current_user).remove(document.blocks.active.find(params[:block_id]), note: params[:note])
          redirect_to textwork_path
        end

        def move
          EditDocument.new(document, current_user).move(document.blocks.active.find(params[:block_id]), position: params[:position], note: params[:note])
          redirect_to textwork_path
        end

        def suggestion
          @suggestion = Suggestion.where(block: document.blocks).not_hidden.find(params[:suggestion_id])
          @block = @suggestion.block
        end

        def decide
          suggestion = Suggestion.where(block: document.blocks).not_hidden.find(params[:suggestion_id])
          EditDocument.new(document, current_user).decide(suggestion, decision: params[:decision], answer: params[:answer].to_s,
                                                                      body: params[:body].to_s, expected_version: params[:expected_version])
          redirect_to textwork_path, notice: t("decidim.textwork.saved")
        end

        def trash
          document.destroy!
          redirect_to textwork_path, notice: t("decidim.textwork.trashed")
        end

        def restore
          Document.with_deleted.find_by!(component: current_component).restore
          redirect_to textwork_path, notice: t("decidim.textwork.restored")
        end

        def export
          locale = params[:language].presence || document.locale
          raise EditDocument::Invalid unless current_organization.available_locales.include?(locale)

          data = ReadingExport.new(document, locale).export
          send_data data, filename: "textwork-#{document.id}-#{locale}.docx", type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        end
      end
    end
  end
end
