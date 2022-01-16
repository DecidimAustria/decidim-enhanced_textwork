# frozen_string_literal: true

class MoveParagraphsFieldsToI18n < ActiveRecord::Migration[5.2]
  def up
    add_column :decidim_enhanced_textwork_paragraphs, :new_title, :jsonb
    add_column :decidim_enhanced_textwork_paragraphs, :new_body, :jsonb

    reset_column_information

    PaperTrail.request(enabled: false) do
      Decidim::EnhancedTextwork::Paragraph.find_each do |paragraph|
        author = paragraph.coauthorships.first.author

        locale = if author
                   author.try(:locale).presence || author.try(:default_locale).presence || author.try(:organization).try(:default_locale).presence
                 elsif paragraph.component && paragraph.component.participatory_space
                   paragraph.component.participatory_space.organization.default_locale
                 else
                   I18n.default_locale.to_s
                 end

        paragraph.new_title = {
          locale => paragraph.title
        }
        paragraph.new_body = {
          locale => paragraph.body
        }

        paragraph.save(validate: false)
      end
    end

    remove_indexs

    remove_column :decidim_enhanced_textwork_paragraphs, :title
    rename_column :decidim_enhanced_textwork_paragraphs, :new_title, :title
    remove_column :decidim_enhanced_textwork_paragraphs, :body
    rename_column :decidim_enhanced_textwork_paragraphs, :new_body, :body

    create_indexs

    reset_column_information
  end

  def down
    add_column :decidim_enhanced_textwork_paragraphs, :new_title, :string
    add_column :decidim_enhanced_textwork_paragraphs, :new_body, :string

    reset_column_information

    Decidim::EnhancedTextwork::Paragraph.find_each do |paragraph|
      paragraph.new_title = paragraph.title.values.first
      paragraph.new_body = paragraph.body.values.first

      paragraph.save!
    end

    remove_indexs

    remove_column :decidim_enhanced_textwork_paragraphs, :title
    rename_column :decidim_enhanced_textwork_paragraphs, :new_title, :title
    remove_column :decidim_enhanced_textwork_paragraphs, :body
    rename_column :decidim_enhanced_textwork_paragraphs, :new_body, :body

    create_indexs

    reset_column_information
  end

  def reset_column_information
    Decidim::User.reset_column_information
    Decidim::Coauthorship.reset_column_information
    Decidim::EnhancedTextwork::Paragraph.reset_column_information
    Decidim::Organization.reset_column_information
  end

  def remove_indexs
    remove_index :decidim_enhanced_textwork_paragraphs, name: "decidim_enhanced_textwork_paragraph_title_search"
    remove_index :decidim_enhanced_textwork_paragraphs, name: "decidim_enhanced_textwork_paragraph_body_search"
  end

  def create_indexs
    execute "CREATE INDEX decidim_enhanced_textwork_paragraph_title_search ON decidim_enhanced_textwork_paragraphs(md5(title::text))"
    execute "CREATE INDEX decidim_enhanced_textwork_paragraph_body_search ON decidim_enhanced_textwork_paragraphs(md5(body::text))"
  end
end
