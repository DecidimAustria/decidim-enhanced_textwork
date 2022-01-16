# frozen_string_literal: true

require "spec_helper"

describe Decidim::EnhancedTextwork::FilteredParagraphs do
  let(:organization) { create(:organization) }
  let(:participatory_process) { create(:participatory_process, organization: organization) }
  let(:component) { create(:paragraph_component, participatory_space: participatory_process) }
  let(:another_component) { create(:paragraph_component, participatory_space: participatory_process) }

  let(:paragraphs) { create_list(:paragraph, 3, component: component) }
  let(:old_paragraphs) { create_list(:paragraph, 3, component: component, created_at: 10.days.ago) }
  let(:another_paragraphs) { create_list(:paragraph, 3, component: another_component) }

  it "returns paragraphs included in a collection of components" do
    expect(described_class.for([component, another_component])).to match_array paragraphs.concat(old_paragraphs, another_paragraphs)
  end

  it "returns paragraphs created in a date range" do
    expect(described_class.for([component, another_component], 2.weeks.ago, 1.week.ago)).to match_array old_paragraphs
  end
end
