# frozen_string_literal: true

require "spec_helper"

describe "Paragraph", type: :system do
  it_behaves_like "paragraphs wizards", with_address: false
  it_behaves_like "paragraphs wizards", with_address: true
end
