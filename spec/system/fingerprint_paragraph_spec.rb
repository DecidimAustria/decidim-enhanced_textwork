# frozen_string_literal: true

require "spec_helper"

describe "Fingerprint paragraph", type: :system do
  let(:manifest_name) { "paragraphs" }

  let!(:fingerprintable) do
    create(:paragraph, component: component)
  end

  include_examples "fingerprint"
end
