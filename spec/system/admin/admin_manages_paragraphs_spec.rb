# frozen_string_literal: true

require "spec_helper"

describe "Admin manages paragraphs", type: :system do
  let(:manifest_name) { "paragraphs" }
  let!(:paragraph) { create :paragraph, component: current_component }
  let!(:reportables) { create_list(:paragraph, 3, component: current_component) }
  let(:participatory_space_path) do
    decidim_admin_participatory_processes.edit_participatory_process_path(participatory_process)
  end

  include_context "when managing a component as an admin"

  it_behaves_like "manage paragraphs"
  it_behaves_like "manage moderations"
  it_behaves_like "export paragraphs"
  it_behaves_like "manage announcements"
  it_behaves_like "manage paragraphs help texts"
  it_behaves_like "when managing paragraphs category as an admin"
  it_behaves_like "when managing paragraphs scope as an admin"
  it_behaves_like "import paragraphs"
  it_behaves_like "manage paragraphs permissions"
  it_behaves_like "merge paragraphs"
  it_behaves_like "split paragraphs"
  it_behaves_like "publish answers"
end
