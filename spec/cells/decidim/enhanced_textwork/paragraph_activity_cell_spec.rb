# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    describe ParagraphActivityCell, type: :cell do
      controller Decidim::LastActivitiesController

      let!(:paragraph) { create(:paragraph) }
      let(:hashtag) { create(:hashtag, name: "myhashtag") }
      let(:action) { :publish }
      let(:action_log) do
        create(
          :action_log,
          action: action,
          resource: paragraph,
          organization: paragraph.organization,
          component: paragraph.component,
          participatory_space: paragraph.participatory_space
        )
      end

      context "when rendering" do
        it "renders the card" do
          html = cell("decidim/enhanced_textwork/paragraph_activity", action_log).call
          expect(html).to have_css("#action-#{action_log.id} .card__content")
        end

        context "when action is update" do
          let(:action) { :update }

          it "renders the correct title" do
            html = cell("decidim/enhanced_textwork/paragraph_activity", action_log).call
            expect(html).to have_css("#action-#{action_log.id} .card__content")
            expect(html).to have_content("Paragraph updated")
          end
        end

        context "when action is create" do
          let(:action) { :create }

          it "renders the correct title" do
            html = cell("decidim/enhanced_textwork/paragraph_activity", action_log).call
            expect(html).to have_css("#action-#{action_log.id} .card__content")
            expect(html).to have_content("New paragraph")
          end
        end

        context "when action is publish" do
          it "renders the correct title" do
            html = cell("decidim/enhanced_textwork/paragraph_activity", action_log).call
            expect(html).to have_css("#action-#{action_log.id} .card__content")
            expect(html).to have_content("New paragraph")
          end
        end

        context "when the paragraph has a hashtags" do
          before do
            body = "Paragraph with #myhashtag"
            parsed_body = Decidim::ContentProcessor.parse(body, current_organization: paragraph.organization)
            paragraph.body = { en: parsed_body.rewrite }
            paragraph.save
          end

          it "correctly renders paragraphs with mentions" do
            html = cell("decidim/enhanced_textwork/paragraph_activity", action_log).call
            expect(html).to have_no_content("gid://")
            expect(html).to have_content("#myhashtag")
          end
        end
      end
    end
  end
end
