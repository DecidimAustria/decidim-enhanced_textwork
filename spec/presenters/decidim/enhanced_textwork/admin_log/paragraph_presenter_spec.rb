# frozen_string_literal: true

require "spec_helper"

describe Decidim::EnhancedTextwork::AdminLog::ParagraphPresenter, type: :helper do
  include_examples "present admin log entry" do
    let(:participatory_space) { create(:participatory_process, organization: organization) }
    let(:component) { create(:paragraph_component, participatory_space: participatory_space) }
    let(:admin_log_resource) { create(:paragraph, component: component) }
    let(:action) { "answer" }
  end
end
