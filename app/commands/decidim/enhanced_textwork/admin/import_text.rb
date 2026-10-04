# frozen_string_literal: true

require "kramdown"

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

            html = Decidim::ContentProcessor.sanitize(@form.content)
            markdown = Kramdown::Document.new(html, input: "html").to_kramdown
            parser = Decidim::Proposals::MarkdownToProposals.new(@form.current_component, @form.current_user)
            parser.parse(markdown)

            unless Decidim::Proposals::Proposal.where(component: @form.current_component).exists?
              @form.errors.add(:content, :blank)
              raise ActiveRecord::Rollback
            end

            document = Decidim::Proposals::ParticipatoryText.find_or_initialize_by(component: @form.current_component)
            document.update!(title: @form.title, description: @form.description)
          end

          broadcast(@form.errors.empty? ? :ok : :invalid)
        end
      end
    end
  end
end
