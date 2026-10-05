# frozen_string_literal: true

require "spec_helper"
require "decidim/enhanced_textwork/legacy_inventory"

RSpec.describe Decidim::EnhancedTextwork::LegacyInventory do
  it "finds legacy data without loading legacy models or altering records" do
    connection = ActiveRecord::Base.connection
    connection.create_table(:decidim_enhanced_textwork_paragraphs) { |table| table.text :body }
    connection.create_table(:textwork_inventory_references) { |table| table.string :resource_type }
    connection.execute("INSERT INTO decidim_enhanced_textwork_paragraphs (body) VALUES ('Private document text')")
    connection.execute("INSERT INTO textwork_inventory_references (resource_type) VALUES ('Decidim::EnhancedTextwork::Paragraph')")
    component = create(:textwork_component)
    component.update_columns(manifest_name: "enhanced_textwork") # rubocop:disable Rails/SkipsModelValidations -- fixture uses an unregistered legacy manifest
    report = described_class.new(connection).report
    expect(report[:components]).to include(hash_including("id" => component.id, "participatory_space_id" => component.participatory_space_id))
    expect(report[:tables]["decidim_enhanced_textwork_paragraphs"]).to eq(1)
    expect(report[:references]["textwork_inventory_references.resource_type"]).to eq(1)
    expect(report[:migration_supported]).to be(false)
    expect(report.to_json).not_to include("Private document text")
    expect(connection.select_value("SELECT body FROM decidim_enhanced_textwork_paragraphs")).to eq("Private document text")
  end
end
