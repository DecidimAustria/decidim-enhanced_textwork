# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module ReadingHelper
      def tw(key, **) = t("decidim.textwork.#{key}", **)

      def textwork_history_enabled? = Access.evaluation_enabled?(current_component)

      def textwork_open?(kind) = Participation.open?(current_component, kind)

      def textwork_closed? = Participation.closed?(current_component)

      def textwork_deadline = Participation.deadline(current_component)&.to_date

      def textwork_number(block) = @numbers ? @numbers[block.id] : block.number

      def textwork_excerpt(block, length: 100)
        text = strip_tags(Markdown.render(textwork_plain(block))).squish
        truncate(text, length:)
      end

      def textwork_liked?(resource)
        return false unless current_user
        return @stats.liked_ids.include?(resource.id) if resource.is_a?(Block) && @stats

        resource.liked_by?(current_user)
      end

      def textwork_block_label(block)
        tw("blocks.open_label", number: textwork_number(block), **@stats.counts.fetch(block.id))
      end

      def textwork_reading(resource, field = :body)
        original = params[:original] == "1"
        locale = original ? resource.original_locale : I18n.locale.to_s
        request = TranslationRequest.request(resource, field, locale) unless original
        data = resource[field].to_h
        data = { resource.original_locale => resource.original(field) }.merge(data)
        value = original ? resource.original(field) : translated_attribute(data, current_organization)
        output = Markdown.render(value)
        missing_translation = locale.to_s != resource.original_locale && data[locale.to_s].blank? && data.dig("machine_translations", locale.to_s).blank?
        output = safe_join([output, textwork_translation_notice(request)]) if missing_translation

        output
      end

      def textwork_translation_notice(request)
        message = request && %w(pending queued).include?(request.status) ? "translation_pending" : "translation_failed"
        content_tag(:p, tw(message), class: "tw-muted", role: "status")
      end

      def textwork_plain(resource, field = :body)
        return resource.original(field) if params[:original] == "1"

        TranslationRequest.request(resource, field, I18n.locale)
        data = { resource.original_locale => resource.original(field) }.merge(resource[field].to_h)
        translated_attribute(data, current_organization)
      end

      def textwork_key(resource) = "#{resource.class.name.demodulize.underscore}-#{resource.id}"

      def textwork_interaction_path(resource, kind)
        interaction_path(resource_type: resource.class.name.demodulize.underscore, resource_id: resource.id, kind:)
      end

      def textwork_diff(original, replacement)
        # Diffy escapes text before wrapping changes; whitespace and punctuation remain significant.
        Diffy::Diff.new(original, replacement, include_plus_and_minus_in_html: false).to_s(:html).html_safe
      end
    end
  end
end
