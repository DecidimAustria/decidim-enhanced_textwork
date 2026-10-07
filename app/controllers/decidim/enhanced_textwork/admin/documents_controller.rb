# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      class DocumentsController < ApplicationController
        helper Decidim::EnhancedTextwork::ReadingHelper
        before_action :authorize_evaluation, only: [:suggestion, :decide]
        rescue_from ReadingExport::MissingTranslation, with: -> { redirect_to textwork_path, alert: t("decidim.textwork.export_missing_translation") }
        rescue_from EditDocument::Conflict, with: -> { redirect_to textwork_path, alert: t("decidim.textwork.conflict") }
        rescue_from EditDocument::Invalid, ActiveRecord::RecordInvalid, with: -> { redirect_to textwork_path, alert: t("decidim.textwork.invalid") }

        def show
          @document = Document.with_deleted.find_by(component: current_component)
          @form = form(ImportForm).from_params(locale: current_organization.default_locale)
          @blocks = @document ? @document.blocks.active.ordered : Block.none
          @suggestions = @document ? Suggestion.where(block: @document.blocks).where(status: "pending").not_hidden.order(:created_at) : Suggestion.none
          @original_editable = @document&.original_editable?
          @has_participation = @document&.participation?
          @evaluation_allowed = @document && Access.evaluation_allowed?(current_user, @document)
        end

        def create
          @form = form(ImportForm).from_params(params)
          unless @form.valid? && @form.title.to_h[@form.locale].present?
            @blocks = Block.none
            @suggestions = Suggestion.none
            return render :show, status: :unprocessable_content
          end
          input = nil
          current_component.with_lock do
            html = @form.document.present? ? DocumentInput.read(@form.document) : @form.content
            input = EditorDocumentInput.new(html, current_organization, images: @form.document.blank?)
            blocks = input.blocks
            raise EditDocument::Invalid if blocks.empty?

            @document = Document.create!(component: current_component, locale: @form.locale, title: @form.title, description: @form.description)
            editor = EditDocument.new(@document, current_user)
            blocks.each { |block| editor.add(**block, origin: "import") }
            @document.document_revisions.create!(number: @document.document_revisions.maximum(:number).to_i + 1, kind: "import", author: current_user,
                                                 details: { blocks: @document.blocks.active.ordered.pluck(:id) })
          end
          redirect_to textwork_path, notice: t("decidim.textwork.imported"), alert: import_warning(input, @form.document.present?)
        rescue DocumentInput::Invalid
          redirect_to textwork_path, alert: t("decidim.textwork.invalid_file")
        end

        def publish_warning
          @images = document.blocks.active.where(kind: "image").includes(editor_image: { file_attachment: :blob }).select(&:missing_image_description?)
        end

        def publish
          document.with_lock do
            raise EditDocument::Invalid unless document.blocks.active.exists?

            if document.published?
              enforce_permission_to(:withdraw, :textwork, document:)
              document.unpublish!
            else
              return redirect_to publish_warning_document_path if document.blocks.active.where(kind: "image").any?(&:missing_image_description?) && params[:confirm_images] != "1"

              document.publish!
            end
          end
          redirect_to textwork_path
        end

        def image_descriptions
          document.with_lock do
            enforce_permission_to(:edit_original, :textwork, document:)
            values = params.fetch(:image_alts, ActionController::Parameters.new).permit!.to_h
            document.blocks.active.where(kind: "image").each do |image|
              image.update!(image_alt: values[image.id.to_s]) if values.has_key?(image.id.to_s)
            end
          end
          redirect_to publish_warning_document_path
        end

        def update
          document.with_lock do
            [:title, :description].each do |field|
              values = params.fetch(field, ActionController::Parameters.new).permit(*current_organization.available_locales).to_h
              source = values.fetch(document.locale, document.original(field))
              previous = document[field].dup
              changed_source = source != document.original(field)
              enforce_permission_to :edit_original, :textwork, document: document if changed_source
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
          @original_editable = document.original_editable?
        end

        def update_block
          block = document.blocks.active.find(params[:block_id])
          document.with_lock do
            block.reload
            raise EditDocument::Conflict unless block.current_version_number == params[:expected_version].to_i

            if block.image?
              enforce_permission_to(:edit_original, :textwork, document:)
              block.update!(image_alt: params[:image_alt].to_s)
              return redirect_to textwork_path, notice: t("decidim.textwork.saved")
            end
            previous = block.body.dup
            body = source_body(block)
            changed_source = block.original != body
            EditDocument.new(document, current_user).update(block, body:, expected_version: params[:expected_version]) if changed_source
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
          # Core Likeable destroys its likes on destroy. Soft-delete via update
          # instead, preserving all feedback and letting Searchable remove its index.
          document.with_lock { document.update!(deleted_at: Time.current) }
          redirect_to textwork_path, notice: t("decidim.textwork.trashed")
        end

        def restore
          restored = Document.with_deleted.find_by!(component: current_component)
          restored.with_lock { restored.restore }
          redirect_to textwork_path, notice: t("decidim.textwork.restored")
        end

        def export
          locale = params[:language].presence || document.locale
          raise EditDocument::Invalid unless current_organization.available_locales.include?(locale)

          data = ReadingExport.new(document, locale).export
          send_data data, filename: "textwork-#{document.id}-#{locale}.docx", type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        end

        private

        def source_body(block) = params.has_key?(:body) ? params[:body].to_s : block.original

        def import_warning(input, file)
          messages = []
          messages << t(file ? "decidim.textwork.admin.import.images_skipped" : "decidim.textwork.images.skipped") if input.skipped_images.positive?
          messages << t("decidim.textwork.admin.import.video_skipped") if input.skipped_video
          messages.join(" ").presence
        end

        def authorize_evaluation
          enforce_permission_to(:evaluate, :textwork, document:)
        end
      end
    end
  end
end
