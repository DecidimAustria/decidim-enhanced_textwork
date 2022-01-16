# frozen_string_literal: true

require "spec_helper"

describe "Admin filters paragraphs", type: :system do
  include_context "when admin manages paragraphs"
  include_context "with filterable context"

  STATES = Decidim::EnhancedTextwork::Paragraph::POSSIBLE_STATES.map(&:to_sym)

  let(:model_name) { Decidim::EnhancedTextwork::Paragraph.model_name }
  let(:resource_controller) { Decidim::EnhancedTextwork::Admin::ParagraphsController }

  def create_paragraph_with_trait(trait)
    create(:paragraph, trait, component: component, skip_injection: true)
  end

  def paragraph_with_state(state)
    Decidim::EnhancedTextwork::Paragraph.where(component: component).find_by(state: state)
  end

  def paragraph_without_state(state)
    Decidim::EnhancedTextwork::Paragraph.where(component: component).where.not(state: state).sample
  end

  context "when filtering by state" do
    let!(:paragraphs) do
      STATES.map { |state| create_paragraph_with_trait(state) }
    end

    before { visit_component_admin }

    STATES.without(:not_answered).each do |state|
      i18n_state = I18n.t(state, scope: "decidim.admin.filters.paragraphs.state_eq.values")

      context "filtering paragraphs by state: #{i18n_state}" do
        it_behaves_like "a filtered collection", options: "State", filter: i18n_state do
          let(:in_filter) { translated(paragraph_with_state(state).title) }
          let(:not_in_filter) { translated(paragraph_without_state(state).title) }
        end
      end
    end

    it_behaves_like "a filtered collection", options: "State", filter: "Not answered" do
      let(:in_filter) { translated(paragraph_with_state(nil).title) }
      let(:not_in_filter) { translated(paragraph_without_state(nil).title) }
    end
  end

  context "when filtering by type" do
    let!(:emendation) { create(:paragraph, component: component, skip_injection: true) }
    let(:emendation_title) { translated(emendation.title) }
    let!(:amendable) { create(:paragraph, component: component, skip_injection: true) }
    let(:amendable_title) { translated(amendable.title) }
    let!(:amendment) { create(:amendment, amendable: amendable, emendation: emendation) }

    before { visit_component_admin }

    it_behaves_like "a filtered collection", options: "Type", filter: "Paragraphs" do
      let(:in_filter) { amendable_title }
      let(:not_in_filter) { emendation_title }
    end

    it_behaves_like "a filtered collection", options: "Type", filter: "Amendments" do
      let(:in_filter) { emendation_title }
      let(:not_in_filter) { amendable_title }
    end
  end

  context "when filtering by scope" do
    let!(:scope1) { create(:scope, organization: organization, name: { "en" => "Scope1" }) }
    let!(:scope2) { create(:scope, organization: organization, name: { "en" => "Scope2" }) }
    let!(:paragraph_with_scope1) { create(:paragraph, component: component, skip_injection: true, scope: scope1) }
    let(:paragraph_with_scope1_title) { translated(paragraph_with_scope1.title) }
    let!(:paragraph_with_scope2) { create(:paragraph, component: component, skip_injection: true, scope: scope2) }
    let(:paragraph_with_scope2_title) { translated(paragraph_with_scope2.title) }

    before { visit_component_admin }

    it_behaves_like "a filtered collection", options: "Scope", filter: "Scope1" do
      let(:in_filter) { paragraph_with_scope1_title }
      let(:not_in_filter) { paragraph_with_scope2_title }
    end

    it_behaves_like "a filtered collection", options: "Scope", filter: "Scope2" do
      let(:in_filter) { paragraph_with_scope2_title }
      let(:not_in_filter) { paragraph_with_scope1_title }
    end
  end

  context "when searching by ID or title" do
    let!(:paragraph1) { create(:paragraph, component: component, skip_injection: true) }
    let!(:paragraph2) { create(:paragraph, component: component, skip_injection: true) }
    let!(:paragraph1_title) { translated(paragraph1.title) }
    let!(:paragraph2_title) { translated(paragraph2.title) }

    before { visit_component_admin }

    it "can be searched by ID" do
      search_by_text(paragraph1.id)

      expect(page).to have_content(paragraph1_title)
    end

    it "can be searched by title" do
      search_by_text(paragraph2_title)

      expect(page).to have_content(paragraph2_title)
    end
  end

  it_behaves_like "paginating a collection" do
    let!(:collection) { create_list(:paragraph, 50, component: component, skip_injection: true) }
  end
end
