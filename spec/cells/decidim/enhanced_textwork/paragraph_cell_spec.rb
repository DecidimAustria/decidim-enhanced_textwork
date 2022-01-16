# frozen_string_literal: true

require "spec_helper"

describe Decidim::EnhancedTextwork::ParagraphCell, type: :cell do
  controller Decidim::EnhancedTextwork::ParagraphsController

  subject { my_cell.call }

  let(:my_cell) { cell("decidim/enhanced_textwork/paragraph", model) }
  let!(:official_paragraph) { create(:paragraph, :official) }
  let!(:user_paragraph) { create(:paragraph) }
  let!(:current_user) { create(:user, :confirmed, organization: model.participatory_space.organization) }

  before do
    allow(controller).to receive(:current_user).and_return(current_user)
  end

  context "when rendering an official paragraph" do
    let(:model) { official_paragraph }

    it "renders the card" do
      expect(subject).to have_css(".card--paragraph")
    end
  end

  context "when rendering a user paragraph" do
    let(:model) { user_paragraph }

    it "renders the card" do
      expect(subject).to have_css(".card--paragraph")
    end
  end
end
