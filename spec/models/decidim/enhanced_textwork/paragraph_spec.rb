# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    describe Paragraph do
      subject { paragraph }

      let(:component) { build :paragraph_component }
      let(:organization) { component.participatory_space.organization }
      let(:paragraph) { create(:paragraph, component: component) }
      let(:coauthorable) { paragraph }

      include_examples "coauthorable"
      include_examples "has component"
      include_examples "has scope"
      include_examples "has category"
      include_examples "has reference"
      include_examples "reportable"
      include_examples "resourceable"

      it { is_expected.to be_valid }
      it { is_expected.to be_versioned }

      describe "newsletter participants" do
        subject { Decidim::EnhancedTextwork::Paragraph.newsletter_participant_ids(paragraph.component) }

        let!(:component_out_of_newsletter) { create(:paragraph_component, organization: organization) }
        let!(:resource_out_of_newsletter) { create(:paragraph, component: component_out_of_newsletter) }
        let!(:resource_in_newsletter) { create(:paragraph, component: paragraph.component) }
        let(:author_ids) { paragraph.notifiable_identities.pluck(:id) + resource_in_newsletter.notifiable_identities.pluck(:id) }

        include_examples "counts commentators as newsletter participants"
      end

      it "has a votes association returning paragraph votes" do
        expect(subject.votes.count).to eq(0)
      end

      describe "#voted_by?" do
        let(:user) { create(:user, organization: subject.organization) }

        it "returns false if the paragraph is not voted by the given user" do
          expect(subject).not_to be_voted_by(user)
        end

        it "returns true if the paragraph is not voted by the given user" do
          create(:paragraph_vote, paragraph: subject, author: user)
          expect(subject).to be_voted_by(user)
        end
      end

      describe "#endorsed_by?" do
        let(:user) { create(:user, organization: subject.organization) }

        context "with User endorsement" do
          it "returns false if the paragraph is not endorsed by the given user" do
            expect(subject).not_to be_endorsed_by(user)
          end

          it "returns true if the paragraph is not endorsed by the given user" do
            create(:endorsement, resource: subject, author: user)
            expect(subject).to be_endorsed_by(user)
          end
        end

        context "with Organization endorsement" do
          let!(:user_group) { create(:user_group, verified_at: Time.current, organization: user.organization) }
          let!(:membership) { create(:user_group_membership, user: user, user_group: user_group) }

          before { user_group.reload }

          it "returns false if the paragraph is not endorsed by the given organization" do
            expect(subject).not_to be_endorsed_by(user, user_group)
          end

          it "returns true if the paragraph is not endorsed by the given organization" do
            create(:endorsement, resource: subject, author: user, user_group: user_group)
            expect(subject).to be_endorsed_by(user, user_group)
          end
        end
      end

      context "when it has been accepted" do
        let(:paragraph) { build(:paragraph, :accepted) }

        it { is_expected.to be_answered }
        it { is_expected.to be_published_state }
        it { is_expected.to be_accepted }
      end

      context "when it has been rejected" do
        let(:paragraph) { build(:paragraph, :rejected) }

        it { is_expected.to be_answered }
        it { is_expected.to be_published_state }
        it { is_expected.to be_rejected }
      end

      describe "#users_to_notify_on_comment_created" do
        let!(:follows) { create_list(:follow, 3, followable: subject) }
        let(:followers) { follows.map(&:user) }
        let(:participatory_space) { subject.component.participatory_space }
        let(:organization) { participatory_space.organization }
        let!(:participatory_process_admin) do
          create(:process_admin, participatory_process: participatory_space)
        end

        context "when the paragraph is official" do
          let(:paragraph) { build(:paragraph, :official) }

          it "returns the followers and the component's participatory space admins" do
            expect(subject.users_to_notify_on_comment_created).to match_array(followers.concat([participatory_process_admin]))
          end
        end

        context "when the paragraph is not official" do
          it "returns the followers and the author" do
            expect(subject.users_to_notify_on_comment_created).to match_array(followers.concat([paragraph.creator.author]))
          end
        end
      end

      describe "#maximum_votes" do
        let(:maximum_votes) { 10 }

        context "when the component's settings are set to an integer bigger than 0" do
          before do
            component[:settings]["global"] = { threshold_per_paragraph: 10 }
            component.save!
          end

          it "returns the maximum amount of votes for this paragraph" do
            expect(paragraph.maximum_votes).to eq(10)
          end
        end

        context "when the component's settings are set to 0" do
          before do
            component[:settings]["global"] = { threshold_per_paragraph: 0 }
            component.save!
          end

          it "returns nil" do
            expect(paragraph.maximum_votes).to be_nil
          end
        end
      end

      describe "#editable_by?" do
        let(:author) { create(:user, organization: organization) }

        context "when user is author" do
          let(:paragraph) { create :paragraph, component: component, users: [author], updated_at: Time.current }

          it { is_expected.to be_editable_by(author) }

          context "when the paragraph has been linked to another one" do
            let(:paragraph) { create :paragraph, component: component, users: [author], updated_at: Time.current }
            let(:original_paragraph) do
              original_component = create(:paragraph_component, organization: organization, participatory_space: component.participatory_space)
              create(:paragraph, component: original_component)
            end

            before do
              paragraph.link_resources([original_paragraph], "copied_from_component")
            end

            it { is_expected.not_to be_editable_by(author) }
          end
        end

        context "when paragraph is from user group and user is admin" do
          let(:user_group) { create :user_group, :verified, users: [author], organization: author.organization }
          let(:paragraph) { create :paragraph, component: component, updated_at: Time.current, users: [author], user_groups: [user_group] }

          it { is_expected.to be_editable_by(author) }
        end

        context "when user is not the author" do
          let(:paragraph) { create :paragraph, component: component, updated_at: Time.current }

          it { is_expected.not_to be_editable_by(author) }
        end

        context "when paragraph is answered" do
          let(:paragraph) { build :paragraph, :with_answer, component: component, updated_at: Time.current, users: [author] }

          it { is_expected.not_to be_editable_by(author) }
        end

        context "when paragraph editing time has run out" do
          let(:paragraph) { build :paragraph, updated_at: 10.minutes.ago, component: component, users: [author] }

          it { is_expected.not_to be_editable_by(author) }
        end

        context "when paragraph edit time is infinite" do
          before do
            component[:settings]["global"] = { paragraph_edit_time: "infinite" }
            component.save!
          end

          let(:paragraph) { build :paragraph, updated_at: 10.years.ago, component: component, users: [author] }

          it do
            paragraph.add_coauthor(author)
            paragraph.save!
            expect(paragraph).to be_editable_by(author)
          end
        end
      end

      describe "#withdrawn?" do
        context "when paragraph is withdrawn" do
          let(:paragraph) { build :paragraph, :withdrawn }

          it { is_expected.to be_withdrawn }
        end

        context "when paragraph is not withdrawn" do
          let(:paragraph) { build :paragraph }

          it { is_expected.not_to be_withdrawn }
        end
      end

      describe "#withdrawable_by" do
        let(:author) { create(:user, organization: organization) }

        context "when user is author" do
          let(:paragraph) { create :paragraph, component: component, users: [author], created_at: Time.current }

          it { is_expected.to be_withdrawable_by(author) }
        end

        context "when user is admin" do
          let(:admin) { build(:user, :admin, organization: organization) }
          let(:paragraph) { build :paragraph, component: component, users: [author], created_at: Time.current }

          it { is_expected.not_to be_withdrawable_by(admin) }
        end

        context "when user is not the author" do
          let(:someone_else) { build(:user, organization: organization) }
          let(:paragraph) { build :paragraph, component: component, users: [author], created_at: Time.current }

          it { is_expected.not_to be_withdrawable_by(someone_else) }
        end

        context "when paragraph is already withdrawn" do
          let(:paragraph) { build :paragraph, :withdrawn, component: component, users: [author], created_at: Time.current }

          it { is_expected.not_to be_withdrawable_by(author) }
        end

        context "when the paragraph has been linked to another one" do
          let(:paragraph) { create :paragraph, component: component, users: [author], created_at: Time.current }
          let(:original_paragraph) do
            original_component = create(:paragraph_component, organization: organization, participatory_space: component.participatory_space)
            create(:paragraph, component: original_component)
          end

          before do
            paragraph.link_resources([original_paragraph], "copied_from_component")
          end

          it { is_expected.not_to be_withdrawable_by(author) }
        end
      end

      context "when answer is not published" do
        let(:paragraph) { create(:paragraph, :accepted_not_published, component: component) }

        it "has accepted as the internal state" do
          expect(paragraph.internal_state).to eq("accepted")
        end

        it "has not_answered as public state" do
          expect(paragraph.state).to be_nil
        end

        it { is_expected.not_to be_accepted }
        it { is_expected.to be_answered }
        it { is_expected.not_to be_published_state }
      end

      describe "#with_valuation_assigned_to" do
        let(:user) { create :user, organization: organization }
        let(:space) { component.participatory_space }
        let!(:valuator_role) { create :participatory_process_user_role, role: :valuator, user: user, participatory_process: space }
        let(:assigned_paragraph) { create :paragraph, component: component }
        let!(:assignment) { create :valuation_assignment, paragraph: assigned_paragraph, valuator_role: valuator_role }

        it "only returns the assigned paragraphs for the given space" do
          results = described_class.with_valuation_assigned_to(user, space)

          expect(results).to eq([assigned_paragraph])
        end
      end
    end
  end
end
