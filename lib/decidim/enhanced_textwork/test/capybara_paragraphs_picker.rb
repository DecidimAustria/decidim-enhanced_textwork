# frozen_string_literal: true

require "decidim/dev/test/rspec_support/capybara_data_picker"

module Capybara
  module EnhancedTextworkPicker
    include DataPicker

    RSpec::Matchers.define :have_paragraphs_picked do |expected|
      match do |paragraphs_picker|
        data_picker = paragraphs_picker.data_picker

        expected.each do |paragraph|
          expect(data_picker).to have_selector(".picker-values div input[value='#{paragraph.id}']", visible: :all)
          expect(data_picker).to have_selector(:xpath, "//div[contains(@class,'picker-values')]/div/a[text()[contains(.,\"#{translated(paragraph.title)}\")]]")
        end
      end
    end

    RSpec::Matchers.define :have_paragraphs_not_picked do |expected|
      match do |paragraphs_picker|
        data_picker = paragraphs_picker.data_picker

        expected.each do |paragraph|
          expect(data_picker).not_to have_selector(".picker-values div input[value='#{paragraph.id}']", visible: :all)
          expect(data_picker).not_to have_selector(:xpath, "//div[contains(@class,'picker-values')]/div/a[text()[contains(.,\"#{translated(paragraph.title)}\")]]")
        end
      end
    end

    def paragraphs_pick(paragraphs_picker, paragraphs)
      data_picker = paragraphs_picker.data_picker

      expect(data_picker).to have_selector(".picker-prompt")
      data_picker.find(".picker-prompt").click

      paragraphs.each do |paragraph|
        data_picker_choose_value(paragraph.id)
      end
      data_picker_close

      expect(paragraphs_picker).to have_paragraphs_picked(paragraphs)
    end

    def paragraphs_remove(paragraphs_picker, paragraphs)
      data_picker = paragraphs_picker.data_picker

      paragraphs.each do |paragraph|
        data_picker.find("a", text: paragraph.title["en"]).find("span").click
      end

      expect(paragraphs_picker).to have_paragraphs_not_picked(paragraphs)
    end
  end
end

RSpec.configure do |config|
  config.include Capybara::ParagraphsPicker, type: :system
end
