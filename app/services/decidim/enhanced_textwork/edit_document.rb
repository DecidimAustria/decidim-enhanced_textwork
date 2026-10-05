# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    # All changes use the document lock first, giving text and structure edits
    # one lock order and one atomic history. No existing records are destroyed.
    class EditDocument
      class Conflict < StandardError; end

      class Invalid < StandardError; end

      def initialize(document, user)
        @document = document
        @user = user
        raise Decidim::ActionForbidden unless Access.admin?(user, document.component)
      end

      def add(body:, kind:, depth: 1, position: nil, origin: "editorial")
        change do
          blocks = @document.blocks.active.ordered.to_a
          position = (position || (blocks.size + 1)).to_i.clamp(1, blocks.size + 1)
          block = @document.blocks.create!(component: @document.component, kind:, heading_depth: depth, position:,
                                           body: { @document.locale => body })
          blocks.insert(position - 1, block)
          reorder(blocks)
          block.block_versions.create!(number: 1, body:, origin:, author: @user)
          record("block_added", block, position:, number: block.number, body:) unless origin == "import"
          notify("structure_changed", block, block.notification_scope.followers.to_a)
          block
        end
      end

      def update(block, body:, expected_version:, origin: "editorial", suggestion: nil)
        change do
          block.reload
          raise Invalid if block.removed?
          raise Conflict unless block.current_version_number == expected_version.to_i
          raise Invalid if body.blank?
          return block if body == block.original && !suggestion

          persist_version(block, body, origin, suggestion)
          notify_text_change(block, suggestion)

          block
        end
      end

      def decide(suggestion, decision:, answer:, body: nil, expected_version: nil)
        change do
          suggestion.reload
          raise Invalid unless suggestion.pending? && !suggestion.block.removed? && !suggestion.hidden?
          raise Invalid unless %w(accepted rejected).include?(decision)

          if decision == "accepted"
            raise Invalid if body.blank? || body.length > 5000

            update(suggestion.block, body:, expected_version:, origin: "suggestion", suggestion:)
          else
            raise Invalid if answer.blank?

            notify("suggestion_rejected", suggestion, [suggestion.author])
          end
          suggestion.update!(status: decision, answer: { @document.locale => answer.to_s }, decided_by: @user, answered_at: Time.current)
          suggestion
        end
      end

      def remove(block, note: nil)
        change do
          block.reload
          raise Invalid if block.removed?

          recipients = (block.heading? ? block : block.notification_scope).followers.to_a
          details = { position: block.position, number: block.number, body: block.original }
          block.suggestions.where(status: "pending").each do |suggestion|
            suggestion.update!(status: "rejected", answer: { @document.locale => I18n.t("decidim.textwork.removed_reason", locale: @document.locale) },
                               decided_by: @user, answered_at: Time.current)
            notify("suggestion_rejected", suggestion, [suggestion.author])
          end
          block.update!(removed_at: Time.current)
          reorder(@document.blocks.active.ordered.to_a)
          record("block_removed", block, **details, note:)
          notify("structure_changed", block, recipients)
        end
      end

      def move(block, position:, note: nil)
        change do
          block.reload
          raise Invalid if block.removed?

          old = { position: block.position, number: block.number }
          recipients = (block.heading? ? block : block.notification_scope).followers.to_a
          blocks = @document.blocks.active.ordered.to_a.reject { |item| item.id == block.id }
          blocks.insert(position.to_i.clamp(1, blocks.size + 1) - 1, block)
          reorder(blocks)
          record("block_moved", block, from: old, to: { position: block.position, number: block.number }, note:)
          recipients += block.notification_scope.followers.to_a
          notify("structure_changed", block, recipients)
        end
      end

      private

      def change(&operation)
        @document.with_lock do
          Decidim.traceability.perform_action!(:update, @document, @user) do
            result = operation.call
            @document.try_update_index_for_search_resource
            result
          end
        end
      end

      def persist_version(block, body, origin, suggestion)
        unchanged_body = body == block.original
        block.replace_original(:body, body)
        block.current_version_number += 1
        unchanged_body ? block.paper_trail.save_with_version : block.save!
        block.block_versions.create!(number: block.current_version_number, body:, origin:, author: @user,
                                     suggestion:, adjusted: !!(suggestion && suggestion.original != body))
      end

      def notify_text_change(block, suggestion)
        scope = block.heading? ? block : block.notification_scope
        recipients = scope.followers.to_a + scope.likes.map(&:author)
        recipients << suggestion.author if suggestion
        notify(suggestion ? "suggestion_accepted" : "editorial_change", suggestion || block, recipients)
      end

      def reorder(blocks)
        blocks.each_with_index { |block, index| block.update_columns(position: index + 1) } # rubocop:disable Rails/SkipsModelValidations -- structure changes have their own history
      end

      def record(kind, block, note: nil, **details)
        @document.document_revisions.create!(number: (@document.document_revisions.maximum(:number) || 0) + 1,
                                             kind:, block:, author: @user, details:, note:)
      end

      def notify(event, resource, recipients)
        return unless @document.published?

        Notifications.deliver(event, resource, recipients, @user)
      end
    end
  end
end
