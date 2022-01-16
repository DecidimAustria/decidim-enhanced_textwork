# frozen_string_literal: true

require "spec_helper"

describe "Paragraph embeds", type: :system do
  include_context "with a component"
  let(:manifest_name) { "paragraphs" }
  let(:resource) { create(:paragraph, component: component) }

  it_behaves_like "an embed resource"
end
