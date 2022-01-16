# frozen_string_literal: true

require "spec_helper"

describe Decidim::EnhancedTextwork::Permissions do
  subject { described_class.new(user, permission_action, context).permissions.allowed? }

  let(:user) { paragraph.creator_author }
  let(:context) do
    {
      current_component: paragraph_component,
      current_settings: current_settings,
      paragraph: paragraph,
      component_settings: component_settings
    }
  end
  let(:paragraph_component) { create :paragraph_component }
  let(:paragraph) { create :paragraph, component: paragraph_component }
  let(:component_settings) do
    double(vote_limit: 2)
  end
  let(:current_settings) do
    double(settings.merge(extra_settings))
  end
  let(:settings) do
    {
      creation_enabled?: false
    }
  end
  let(:extra_settings) { {} }
  let(:permission_action) { Decidim::PermissionAction.new(action) }

  context "when scope is admin" do
    let(:action) do
      { scope: :admin, action: :vote, subject: :paragraph }
    end

    it_behaves_like "delegates permissions to", Decidim::EnhancedTextwork::Admin::Permissions
  end

  context "when scope is not public" do
    let(:action) do
      { scope: :foo, action: :vote, subject: :paragraph }
    end

    it_behaves_like "permission is not set"
  end

  context "when subject is not a paragraph" do
    let(:action) do
      { scope: :public, action: :vote, subject: :foo }
    end

    it_behaves_like "permission is not set"
  end

  context "when creating a paragraph" do
    let(:action) do
      { scope: :public, action: :create, subject: :paragraph }
    end

    context "when creation is disabled" do
      let(:extra_settings) { { creation_enabled?: false } }

      it { is_expected.to eq false }
    end

    context "when user is authorized" do
      let(:extra_settings) { { creation_enabled?: true } }

      it { is_expected.to eq true }
    end
  end

  context "when editing a paragraph" do
    let(:action) do
      { scope: :public, action: :edit, subject: :paragraph }
    end

    before do
      allow(paragraph).to receive(:editable_by?).with(user).and_return(editable)
    end

    context "when paragraph is editable" do
      let(:editable) { true }

      it { is_expected.to eq true }
    end

    context "when paragraph is not editable" do
      let(:editable) { false }

      it { is_expected.to eq false }
    end
  end

  context "when withdrawing a paragraph" do
    let(:action) do
      { scope: :public, action: :withdraw, subject: :paragraph }
    end

    context "when paragraph author is the user trying to withdraw" do
      it { is_expected.to eq true }
    end

    context "when trying by another user" do
      let(:user) { build :user }

      it { is_expected.to eq false }
    end
  end

  describe "voting" do
    let(:action) do
      { scope: :public, action: :vote, subject: :paragraph }
    end

    context "when voting is disabled" do
      let(:extra_settings) do
        {
          votes_enabled?: false,
          votes_blocked?: true
        }
      end

      it { is_expected.to eq false }
    end

    context "when votes are blocked" do
      let(:extra_settings) do
        {
          votes_enabled?: true,
          votes_blocked?: true
        }
      end

      it { is_expected.to eq false }
    end

    context "when the user has no more remaining votes" do
      let(:extra_settings) do
        {
          votes_enabled?: true,
          votes_blocked?: false
        }
      end

      before do
        paragraphs = create_list :paragraph, 2, component: paragraph_component
        create :paragraph_vote, author: user, paragraph: paragraphs[0]
        create :paragraph_vote, author: user, paragraph: paragraphs[1]
      end

      it { is_expected.to eq false }
    end

    context "when the user is authorized" do
      let(:extra_settings) do
        {
          votes_enabled?: true,
          votes_blocked?: false
        }
      end

      it { is_expected.to eq true }
    end
  end

  describe "unvoting" do
    let(:action) do
      { scope: :public, action: :unvote, subject: :paragraph }
    end

    context "when voting is disabled" do
      let(:extra_settings) do
        {
          votes_enabled?: false,
          votes_blocked?: true
        }
      end

      it { is_expected.to eq false }
    end

    context "when votes are blocked" do
      let(:extra_settings) do
        {
          votes_enabled?: true,
          votes_blocked?: true
        }
      end

      it { is_expected.to eq false }
    end

    context "when the user is authorized" do
      let(:extra_settings) do
        {
          votes_enabled?: true,
          votes_blocked?: false
        }
      end

      it { is_expected.to eq true }
    end
  end

  describe "amend" do
    let(:action) do
      { scope: :public, action: :amend, subject: :paragraph }
    end

    context "when amend is disabled" do
      let(:extra_settings) do
        {
          amendments_enabled?: false
        }
      end

      it { is_expected.to eq false }
    end

    context "when the user is authorized" do
      let(:extra_settings) do
        {
          amendments_enabled?: true
        }
      end

      it { is_expected.to eq true }
    end
  end
end
