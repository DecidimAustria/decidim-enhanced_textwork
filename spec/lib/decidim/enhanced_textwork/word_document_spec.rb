# frozen_string_literal: true

require "spec_helper"
require "decidim/enhanced_textwork/word_document"

RSpec.describe Decidim::EnhancedTextwork::WordDocument do
  it "writes valid XML, preserves Unicode and escapes text without fetching HTML resources" do
    document = described_class.new
    document.paragraph("Änderungen & <Vorschläge>", heading: true)
    document.html("<p>First</p><p>Second<br>Third</p><script>secret()</script>")
    Zip::File.open_buffer(document.render) do |zip|
      expect(zip.entries.map(&:name)).to contain_exactly("[Content_Types].xml", "_rels/.rels", "word/document.xml")
      xml = Nokogiri::XML(zip.read("word/document.xml"), &:strict)
      expect(xml.text).to include("Änderungen & <Vorschläge>", "First", "Second", "Third")
      expect(xml.text).not_to include("secret()")
    end
  end
end
