# frozen_string_literal: true

require "spec_helper"

describe "Search paragraphs", type: :system do
  include_context "with a component"
  let(:participatory_process) do
    create(:participatory_process, :published, :with_steps, organization: organization)
  end
  let(:manifest_name) { "paragraphs" }
  let!(:searchables) { create_list(:paragraph, 3, component: component) }
  let!(:term) { translated(searchables.first.title).split(" ").last }
  let(:component) { create(:paragraph_component, participatory_space: participatory_process) }
  let(:hashtag) { "#decidim" }

  before do
    hashtag_paragraph = create(:paragraph, component: component, title: "A paragraph with a hashtag #{hashtag}")
    searchables << hashtag_paragraph
    searchables.each { |s| s.update(published_at: Time.current) }
  end

  include_examples "searchable results"
end
