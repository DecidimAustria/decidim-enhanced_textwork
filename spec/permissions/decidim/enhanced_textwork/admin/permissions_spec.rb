# frozen_string_literal: true

require "spec_helper"

describe Decidim::EnhancedTextwork::Admin::Permissions do
  subject { described_class.new(user, permission_action, context).permissions.allowed? }

  let(:user) { build :user, :admin }
  let(:current_component) { create(:paragraph_component) }
  let(:paragraph) { nil }
  let(:extra_context) { {} }
  let(:context) do
    {
      paragraph: paragraph,
      current_component: current_component,
      current_settings: current_settings,
      component_settings: component_settings
    }.merge(extra_context)
  end
  let(:component_settings) do
    double(
      official_paragraphs_enabled: official_paragraphs_enabled?,
      paragraph_answering_enabled: component_settings_paragraph_answering_enabled?,
      participatory_texts_enabled?: component_settings_participatory_texts_enabled?
    )
  end
  let(:current_settings) do
    double(
      creation_enabled?: creation_enabled?,
      paragraph_answering_enabled: current_settings_paragraph_answering_enabled?,
      publish_answers_immediately: current_settings_publish_answers_immediately?
    )
  end
  let(:creation_enabled?) { true }
  let(:official_paragraphs_enabled?) { true }
  let(:component_settings_paragraph_answering_enabled?) { true }
  let(:component_settings_participatory_texts_enabled?) { true }
  let(:current_settings_paragraph_answering_enabled?) { true }
  let(:current_settings_publish_answers_immediately?) { true }
  let(:permission_action) { Decidim::PermissionAction.new(action) }

  shared_examples "can create paragraph notes" do
    describe "paragraph note creation" do
      let(:action) do
        { scope: :admin, action: :create, subject: :paragraph_note }
      end

      context "when the space allows it" do
        it { is_expected.to eq true }
      end
    end
  end

  shared_examples "can answer paragraphs" do
    describe "paragraph answering" do
      let(:action) do
        { scope: :admin, action: :create, subject: :paragraph_answer }
      end

      context "when everything is OK" do
        it { is_expected.to eq true }
      end

      context "when answering is disabled in the step level" do
        let(:current_settings_paragraph_answering_enabled?) { false }

        it { is_expected.to eq false }
      end

      context "when answering is disabled in the component level" do
        let(:component_settings_paragraph_answering_enabled?) { false }

        it { is_expected.to eq false }
      end
    end
  end

  shared_examples "can export paragraphs" do
    describe "export paragraphs" do
      let(:action) do
        { scope: :admin, action: :export, subject: :paragraphs }
      end

      context "when everything is OK" do
        it { is_expected.to eq true }
      end
    end
  end

  context "when user is a valuator" do
    let(:organization) { space.organization }
    let(:space) { current_component.participatory_space }
    let!(:valuator_role) { create :participatory_process_user_role, user: user, role: :valuator, participatory_process: space }
    let!(:user) { create :user, organization: organization }

    context "and can valuate the current paragraph" do
      let(:paragraph) { create :paragraph, component: current_component }
      let!(:assignment) { create :valuation_assignment, paragraph: paragraph, valuator_role: valuator_role }

      it_behaves_like "can create paragraph notes"
      it_behaves_like "can answer paragraphs"
      it_behaves_like "can export paragraphs"
    end

    context "when current user is the valuator" do
      describe "unassign paragraphs from themselves" do
        let(:action) do
          { scope: :admin, action: :unassign_from_valuator, subject: :paragraphs }
        end
        let(:extra_context) { { valuator: user } }

        it { is_expected.to eq true }
      end
    end
  end

  it_behaves_like "can create paragraph notes"
  it_behaves_like "can answer paragraphs"
  it_behaves_like "can export paragraphs"

  describe "paragraph creation" do
    let(:action) do
      { scope: :admin, action: :create, subject: :paragraph }
    end

    context "when everything is OK" do
      it { is_expected.to eq true }
    end

    context "when creation is disabled" do
      let(:creation_enabled?) { false }

      it { is_expected.to eq false }
    end

    context "when official paragraphs are disabled" do
      let(:official_paragraphs_enabled?) { false }

      it { is_expected.to eq false }
    end
  end

  describe "paragraph edition" do
    let(:action) do
      { scope: :admin, action: :edit, subject: :paragraph }
    end

    context "when the paragraph is not official" do
      let(:paragraph) { create :paragraph, component: current_component }

      it_behaves_like "permission is not set"
    end

    context "when the paragraph is official" do
      let(:paragraph) { create :paragraph, :official, component: current_component }

      context "when everything is OK" do
        it { is_expected.to eq true }
      end

      context "when it has some votes" do
        before do
          create :paragraph_vote, paragraph: paragraph
        end

        it_behaves_like "permission is not set"
      end
    end
  end

  describe "update paragraph category" do
    let(:action) do
      { scope: :admin, action: :update, subject: :paragraph_category }
    end

    it { is_expected.to eq true }
  end

  describe "import paragraphs from another component" do
    let(:action) do
      { scope: :admin, action: :import, subject: :paragraphs }
    end

    it { is_expected.to eq true }
  end

  describe "split paragraphs" do
    let(:action) do
      { scope: :admin, action: :split, subject: :paragraphs }
    end

    it { is_expected.to eq true }
  end

  describe "merge paragraphs" do
    let(:action) do
      { scope: :admin, action: :merge, subject: :paragraphs }
    end

    it { is_expected.to eq true }
  end

  describe "paragraph answers publishing" do
    let(:user) { create(:user) }
    let(:action) do
      { scope: :admin, action: :publish_answers, subject: :paragraphs }
    end

    it { is_expected.to eq false }

    context "when user is an admin" do
      let(:user) { create(:user, :admin) }

      it { is_expected.to eq true }
    end
  end

  describe "assign paragraphs to a valuator" do
    let(:action) do
      { scope: :admin, action: :assign_to_valuator, subject: :paragraphs }
    end

    it { is_expected.to eq true }
  end

  describe "unassign paragraphs from a valuator" do
    let(:action) do
      { scope: :admin, action: :unassign_from_valuator, subject: :paragraphs }
    end

    it { is_expected.to eq true }
  end

  describe "manage participatory texts" do
    let(:action) do
      { scope: :admin, action: :manage, subject: :participatory_texts }
    end

    it { is_expected.to eq true }
  end
end
