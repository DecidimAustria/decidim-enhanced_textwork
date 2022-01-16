# frozen_string_literal: true

require "spec_helper"

describe "Report Paragraph", type: :system do
  include_context "with a component"

  let(:manifest_name) { "paragraphs" }
  let!(:paragraphs) { create_list(:paragraph, 3, component: component) }
  let(:reportable) { paragraphs.first }
  let(:reportable_path) { resource_locator(reportable).path }
  let!(:user) { create :user, :confirmed, organization: organization }

  let!(:component) do
    create(:paragraph_component,
           manifest: manifest,
           participatory_space: participatory_process)
  end

  include_examples "reports"
end
