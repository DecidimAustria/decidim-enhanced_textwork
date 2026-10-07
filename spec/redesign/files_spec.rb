# frozen_string_literal: true

require "spec_helper"
require "zip"

RSpec.describe "Redesign imports and exports" do
  def upload(name, content)
    Struct.new(:original_filename, :data) do
      def size = data.bytesize

      def read(limit) = data.byteslice(0, limit)
    end.new(name, content)
  end

  def archive(name, xml)
    Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry(name)
      zip.write(xml)
    end.string
  end

  it "imports an entire Word list as one paragraph" do
    xml = '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body><w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr><w:r><w:t>Chapter</w:t></w:r></w:p><w:p><w:pPr><w:numPr><w:numId w:val="1"/></w:numPr></w:pPr><w:r><w:t>First</w:t></w:r></w:p><w:p><w:pPr><w:numPr><w:numId w:val="1"/></w:numPr></w:pPr><w:r><w:t>Second</w:t></w:r></w:p></w:body></w:document>'
    html = Decidim::EnhancedTextwork::DocumentInput.read(upload("text.docx", archive("word/document.xml", xml)))
    blocks = Decidim::EnhancedTextwork::Markdown.from_html(html)
    expect(blocks.map { |block| block[:kind] }).to eq(%w(heading paragraph))
    expect(blocks.last[:body]).to eq("- First\n- Second")
  end

  it "rejects XML entity declarations" do
    file = upload("text.docx", archive("word/document.xml", '<!DOCTYPE x [<!ENTITY e SYSTEM "file:///etc/passwd">]><x>&e;</x>'))
    expect { Decidim::EnhancedTextwork::DocumentInput.read(file) }.to raise_error(Decidim::EnhancedTextwork::DocumentInput::Invalid)
  end

  it "exports one selected language and refuses a mixed-language report" do
    document = create(:textwork_document, published_at: nil, title: { en: "A plan", de: "Ein Plan" }, description: { en: "", de: "" })
    admin = create(:user, :admin, organization: document.organization)
    block = Decidim::EnhancedTextwork::EditDocument.new(document, admin).add(kind: "paragraph", body: "More trees.")
    document.publish!
    expect { Decidim::EnhancedTextwork::ReadingExport.new(document, "de").export }.to raise_error(Decidim::EnhancedTextwork::ReadingExport::MissingTranslation)
    block.update!(body: block.body.merge("de" => "Mehr Bäume."))
    data = Decidim::EnhancedTextwork::ReadingExport.new(document, "de").export
    xml = nil
    Zip::File.open_buffer(data) { |zip| xml = zip.read("word/document.xml") }
    expect(xml.force_encoding("UTF-8")).to include("Mehr Bäume.")
    expect(xml).not_to include("More trees.")
  end

  it "exports paragraph likes and suggestions in agreement order with author, date, reason and likes" do
    document = create(:textwork_document, published_at: nil)
    admin = create(:user, :admin, organization: document.organization)
    block = Decidim::EnhancedTextwork::EditDocument.new(document, admin).add(kind: "paragraph", body: "More trees.")
    document.publish!
    author = create(:user, :confirmed, organization: document.organization)
    low = block.suggestions.create!(component: document.component, author:, block_version: block.current_version,
                                    body: { en: "Trees and benches." }, justification: { en: "A place to rest." },
                                    changeset: { original: block.original, replace: "Trees and benches." })
    high = block.suggestions.create!(component: document.component, author:, block_version: block.current_version,
                                     body: { en: "Trees and water." }, changeset: { original: block.original, replace: "Trees and water." })
    [block, high].each { |resource| Decidim::Like.create!(resource:, author: admin) }
    bytes = Decidim::EnhancedTextwork::ReadingExport.new(document, "en").export
    Zip::File.open_buffer(bytes) do |zip|
      xml = zip.read("word/document.xml").force_encoding("UTF-8")
      expect(xml).to include("Agreements: 1", "Agreements: 0", author.name, I18n.l(low.created_at.to_date), "A place to rest.")
      expect(xml.index("Trees and water.")).to be < xml.index("Trees and benches.")
    end
  end
end
