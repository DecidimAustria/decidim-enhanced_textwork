# frozen_string_literal: true

require "spec_helper"

describe "Follow paragraphs", type: :system do
  let(:manifest_name) { "paragraphs" }

  let!(:followable) do
    create(:paragraph, component: component)
  end

  let(:followable_path) { resource_locator(followable).path }

  include_examples "follows"
end
