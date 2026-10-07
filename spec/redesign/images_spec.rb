# frozen_string_literal: true

require "spec_helper"
require "zip"

RSpec.describe "Textwork images", type: :request do
  let(:document) { create(:textwork_document, published_at: nil) }
  let(:admin) { create(:user, :admin, :confirmed, organization: document.organization) }
  let(:editor) { Decidim::EnhancedTextwork::EditDocument.new(document, admin) }
  let(:routes) { Decidim::EngineRouter.admin_proxy(document.component) }
  let(:image) { create(:editor_image, organization: document.organization, author: admin) }
  let(:url) { Rails.application.routes.url_helpers.rails_blob_path(image.file, only_path: true) }

  before do
    host! document.organization.host
    sign_in admin
  end

  it "imports a real Core editor upload and retains its attachment after clearing the source editor" do
    empty_component = create(:textwork_component, :published, participatory_space: document.participatory_space)
    import_routes = Decidim::EngineRouter.admin_proxy(empty_component)
    core = Decidim::Core::Engine.routes.url_helpers
    address = nil
    image.file.blob.open do |file|
      upload = Rack::Test::UploadedFile.new(file.path, image.file.content_type, original_filename: "trees.png")
      post core.editor_images_path, params: { image: upload }
      expect(response).to have_http_status(:ok)
      address = JSON.parse(response.body).fetch("url")
    end
    post import_routes.create_document_path, params: { import: { title: { en: "Illustrated plan" }, locale: "en", content: "<img src='#{address}' alt='A leafy street'><p>More trees.</p><video src='ignored.mp4'></video>" } }
    imported = Decidim::EnhancedTextwork::Document.find_by!(component: empty_component)
    figure = imported.blocks.ordered.first
    expect(figure.image_alt).to eq("A leafy street")
    expect(figure.editor_image.file).to be_attached
    expect(imported.blocks.pluck(:kind)).to eq(%w(image paragraph))
    expect(flash[:alert]).to include("Videos are not imported.")
    # No editor HTML is stored on the document; clearing the source cannot break
    # the foreign key/attachment that the imported block holds.
    patch import_routes.update_document_path, params: { title: { en: "Illustrated plan" }, description: { en: "" } }
    figure.reload
    expect(figure.editor_image.file.blob).to be_present
    patch import_routes.publish_document_path
    public_routes = Decidim::EngineRouter.main_proxy(empty_component)
    get public_routes.document_path(imported)
    html = Nokogiri::HTML(response.body)
    expect(html.at_css(".tw-image img")["src"]).to include("/representations/")
    expect(html.at_css(".tw-image button")["data-image-url"]).to include("/blobs/")
    expect(html.at_css(".tw-image img")["alt"]).to eq("A leafy street")
  end

  it "splits uploaded images from paragraphs and moves list images after the complete list" do
    input = Decidim::EnhancedTextwork::EditorDocumentInput.new("<p>Before <a href='https://example.org'><img src='#{url}' alt='Trees' width='10'></a> after.</p><ul><li>One<img src='#{url}'></li><li>Two</li></ul>", document.organization)
    blocks = input.blocks
    expect(blocks.map { |item| item[:kind] }).to eq(%w(paragraph image paragraph paragraph image))
    expect(blocks[0][:body]).to eq("Before")
    expect(blocks[2][:body]).to eq("after.")
    expect(blocks[3][:body]).to eq("- One\n- Two")
    expect(blocks[1]).to include(editor_image: image, image_alt: "Trees")
    expect(input.skipped_images).to eq(0)
  end

  it "ignores external, foreign and file-import images without fetching them" do
    foreign = create(:editor_image)
    foreign_url = Rails.application.routes.url_helpers.rails_blob_path(foreign.file, only_path: true)
    input = Decidim::EnhancedTextwork::EditorDocumentInput.new("<p>Text<img src='https://example.org/file.png'><img src='#{foreign_url}'></p><iframe src='https://example.org'></iframe>", document.organization)
    expect(input.blocks).to eq([{ kind: "paragraph", body: "Text" }])
    expect(input.skipped_images).to eq(2)
    expect(input.skipped_video).to be(true)
    input = Decidim::EnhancedTextwork::EditorDocumentInput.new("<p>Text<img src='#{url}'></p>", document.organization, images: false)
    expect(input.blocks.size).to eq(1)
  end

  it "preserves images without numbering or participation and exports a textual placeholder" do
    editor.add(kind: "heading", body: "Chapter")
    first = editor.add(kind: "paragraph", body: "First.")
    figure = editor.add(kind: "image", editor_image: image, image_alt: "Trees beside a road")
    second = editor.add(kind: "paragraph", body: "Second.")
    expect([first.number, figure.number, second.number]).to eq(["1.1", nil, "1.2"])
    expect(figure).not_to be_likeable
    expect(figure).not_to be_commentable
    expect(figure).not_to be_followable
    expect(figure.display_image.variation.transformations).to include(resize_to_limit: [1600, 1600])
    bytes = Decidim::EnhancedTextwork::ReadingExport.new(document, "en").export
    Zip::File.open_buffer(bytes) do |zip|
      expect(zip.read("word/document.xml").force_encoding("UTF-8")).to include("[Figure: Trees beside a road]")
      expect(zip.glob("word/media/*")).to be_empty
    end
  end

  it "warns before publishing missing alternatives and allows an explicit decorative-image decision" do
    figure = editor.add(kind: "image", editor_image: image, image_alt: "")
    patch routes.publish_document_path
    expect(response).to redirect_to(routes.publish_warning_document_path)
    expect(document.reload).not_to be_published
    get routes.publish_warning_document_path
    expect(response.body).to include("Review image descriptions", "image_alts[#{figure.id}]")
    patch routes.image_descriptions_document_path, params: { image_alts: { figure.id.to_s => "An accessible description" } }
    expect(figure.reload.image_alt).to eq("An accessible description")
    patch routes.publish_document_path
    expect(document.reload).to be_published
    document.unpublish!
    figure.update!(image_alt: "")
    patch routes.publish_document_path, params: { confirm_images: "1" }
    expect(document.reload).to be_published
  end
end
