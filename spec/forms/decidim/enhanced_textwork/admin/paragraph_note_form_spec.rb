# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    module Admin
      describe ParagraphNoteForm do
        subject { form }

        let(:organization) { create(:organization) }
        let(:body) { Decidim::Faker::Localized.sentence(word_count: 3) }
        let(:params) do
          {
            body: body
          }
        end

        let(:form) do
          described_class.from_params(params).with_context(
            current_organization: organization
          )
        end

        context "when everything is OK" do
          it { is_expected.to be_valid }
        end

        context "when the body is not presence" do
          let(:body) { nil }

          it { is_expected.to be_invalid }
        end
      end
    end
  end
end
