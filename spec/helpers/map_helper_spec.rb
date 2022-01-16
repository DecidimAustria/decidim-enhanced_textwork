# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    describe MapHelper do
      include Decidim::LayoutHelper

      let!(:organization) { create(:organization) }
      let!(:paragraph_component) { create(:paragraph_component, :with_geocoding_enabled, organization: organization) }
      let!(:user) { create(:user, organization: organization) }
      let!(:paragraphs) { create_list(:paragraph, 5, address: address, latitude: latitude, longitude: longitude, component: paragraph_component) }
      let!(:paragraph) { paragraphs.first }
      let(:address) { "Carrer Pic de Peguera 15, 17003 Girona" }
      let(:latitude) { 40.1234 }
      let(:longitude) { 2.1234 }

      describe "#has_position?" do
        subject { helper.has_position?(paragraph) }

        it { is_expected.to be_truthy }

        context "when paragraph is not geocoded" do
          let!(:paragraphs) { create_list(:paragraph, 5, address: address, latitude: nil, longitude: nil, component: paragraph_component) }

          it { is_expected.to be_falsey }
        end
      end

      describe "#paragraph_preview_data_for_map" do
        subject { helper.paragraph_preview_data_for_map(paragraph) }

        let(:marker) { subject[:marker] }

        it "returns preview data" do
          expect(subject[:type]).to eq("drag-marker")
          expect(marker["latitude"]).to eq(latitude)
          expect(marker["longitude"]).to eq(longitude)
          expect(marker["address"]).to eq(address)
          expect(marker["icon"]).to match(/<svg.+/)
        end
      end

      describe "#paragraph_data_for_map" do
        subject { helper.paragraph_data_for_map(paragraph) }

        let(:fake_body) { "<script>alert(\"HEY\")</script> This is my long, but still super interesting, body of my also long, but also super interesting, paragraph. Check it out!" }
        let(:fake_title) { "<script>alert(\"HEY\")</script> This is my title" }

        before do
          allow(helper).to receive(:paragraph_path).and_return(Decidim::EnhancedTextwork::ParagraphPresenter.new(paragraph).paragraph_path)
        end

        it "returns preview data" do
          allow(paragraph).to receive(:body).and_return(en: fake_body)
          allow(paragraph).to receive(:title).and_return(en: fake_title)

          expect(subject["latitude"]).to eq(latitude)
          expect(subject["longitude"]).to eq(longitude)
          expect(subject["address"]).to eq(address)
          expect(subject["title"]).to eq("&lt;script&gt;alert(&quot;HEY&quot;)&lt;/script&gt; This is my title")
          expect(subject["body"]).to eq("alert(&quot;HEY&quot;) This is my long, but still super interesting, body of my also long, but also super inte...")
          expect(subject["link"]).to eq(Decidim::EnhancedTextwork::ParagraphPresenter.new(paragraph).paragraph_path)
          expect(subject["icon"]).to match(/<svg.+/)
        end
      end

      describe "#paragraphs_data_for_map" do
        subject { helper.paragraphs_data_for_map(paragraphs) }

        before do
          allow(helper).to receive(:paragraph_path).and_return(Decidim::EnhancedTextwork::ParagraphPresenter.new(paragraph).paragraph_path)
        end

        it "returns preview data" do
          expect(subject.length).to eq(5)
        end
      end
    end
  end
end
