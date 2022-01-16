# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      # This class contains helpers needed to show the Paragraphs picker.
      #
      module EnhancedTextworkPickerHelper
        def paragraphs_picker(form, field, url)
          picker_options = {
            id: sanitize_to_id(field),
            class: "picker-multiple",
            name: "#{form.object_name}[#{field.to_s.sub(/s$/, "_ids")}]",
            multiple: true,
            autosort: true
          }

          prompt_params = {
            url: url,
            text: t("paragraphs_picker.choose_paragraphs", scope: "decidim.enhanced_textwork")
          }

          form.data_picker(field, picker_options, prompt_params) do |item|
            { url: url, text: present(item).id_and_title }
          end
        end
      end
    end
  end
end
