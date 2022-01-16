# frozen_string_literal: true

require "spec_helper"

describe "Show a Paragraph", type: :system do
  include_context "with a component"
  let(:manifest_name) { "paragraphs" }
  let(:paragraph) { create :paragraph, component: component }

  def visit_paragraph
    visit resource_locator(paragraph).path
  end

  describe "paragraph show" do
    it_behaves_like "editable content for admins" do
      let(:target_path) { resource_locator(paragraph).path }
    end

    context "when requesting the paragraph path" do
      before do
        visit_paragraph
      end

      it_behaves_like "share link"

      describe "extra admin link" do
        before do
          login_as user, scope: :user
          visit current_path
        end

        context "when I'm an admin user" do
          let(:user) { create(:user, :admin, :confirmed, organization: organization) }

          it "has a link to answer to the paragraph at the admin" do
            within ".topbar" do
              expect(page).to have_link("Answer", href: /.*admin.*paragraph-answer.*/)
            end
          end
        end

        context "when I'm a regular user" do
          let(:user) { create(:user, :confirmed, organization: organization) }

          it "does not have a link to answer the paragraph at the admin" do
            within ".topbar" do
              expect(page).not_to have_link("Answer")
            end
          end
        end
      end

      describe "author tooltip" do
        let(:user) { create(:user, :confirmed, organization: organization) }

        before do
          login_as user, scope: :user
          visit current_path
        end

        context "when author doesn't restrict messaging" do
          it "includes a link to message the paragraph author" do
            within ".author-data" do
              find_link.hover
            end
            expect(page).to have_link("Send private message")
          end
        end
      end
    end
  end
end
