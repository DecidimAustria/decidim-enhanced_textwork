# frozen_string_literal: true

class FixParagraphsData < ActiveRecord::Migration[5.2]
  def up
    reset_column_information

    PaperTrail.request(enabled: false) do
      Decidim::EnhancedTextwork::Paragraph.find_each do |paragraph|
        next if paragraph.title.is_a?(Hash) && paragraph.body.is_a?(Hash)

        author = paragraph.coauthorships.first.author

        locale = author.try(:locale).presence || author.try(:default_locale).presence || author.try(:organization).try(:default_locale).presence

        # rubocop:disable Rails/SkipsModelValidations
        values = {}
        values[:title] = { locale => paragraph.title } unless paragraph.title.is_a?(Hash)
        values[:body] = { locale => paragraph.body } unless paragraph.body.is_a?(Hash)

        paragraph.update_columns(values)
        # rubocop:enable Rails/SkipsModelValidations
      end
    end

    reset_column_information
  end

  def down; end

  def reset_column_information
    Decidim::User.reset_column_information
    Decidim::Coauthorship.reset_column_information
    Decidim::EnhancedTextwork::Paragraph.reset_column_information
    Decidim::Organization.reset_column_information
  end
end
