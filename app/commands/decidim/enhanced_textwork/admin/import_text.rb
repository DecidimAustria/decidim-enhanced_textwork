# frozen_string_literal: true

module Decidim
  module EnhancedTextwork
    module Admin
      class ImportText < Decidim::Command
        def initialize(form)
          @form = form
        end

        def call
          @form.current_component.with_lock do
            return broadcast(:invalid) unless @form.valid?

            content = @form.document.present? ? DocumentInput.read(@form.document) : @form.content
            nodes = Nokogiri::HTML.fragment(Decidim::ContentProcessor.sanitize(content)).children.select { |node| node.text.strip.present? }
            if nodes.empty?
              @form.errors.add(:content, :blank)
              return broadcast(:invalid)
            end
            document = Document.create!(component: @form.current_component, title: @form.title, description: @form.description)
            article_number = 0
            nodes.each_with_index do |node, index|
              heading = node.name.match?(/\Ah[1-6]\z/)
              article_number += 1 unless heading
              level = heading ? (node.name == "h1" ? "section" : "sub-section") : "article"
              section = document.sections.create!(component: document.component, position: index + 1, level:)
              locale = I18n.locale.to_s
              revision = section.revisions.create!(number: 1, author: @form.current_user,
                                                   title: { locale => heading ? node.text : article_number.to_s },
                                                   body: { locale => heading ? node.text : node.to_html })
              section.update!(current_revision: revision)
            end
          end
          broadcast(:ok)
        rescue DocumentInput::Invalid
          @form.errors.add(:document, I18n.t("decidim.enhanced_textwork.admin.invalid_document"))
          broadcast(:invalid)
        end
      end
    end
  end
end
