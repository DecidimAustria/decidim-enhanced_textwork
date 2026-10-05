# frozen_string_literal: true

require "spec_helper"
RSpec.describe Decidim::EnhancedTextwork::DocumentInput do
  def upload(data, filename)
    file = Tempfile.new("textwork-import")
    file.binmode
    file.write(data)
    file.rewind
    ActionDispatch::Http::UploadedFile.new(tempfile: file, filename:)
  end
  it "reads Markdown headings and formatted paragraphs without Proposals" do
    html = described_class.read(upload("# Plan\n\nMore **trees**.", "plan.md"))
    expect(html).to include("<h1", "<strong>trees</strong>")
  end

  it "reads ODT document headings and paragraphs" do
    buffer = Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry("content.xml")
      zip.write('<office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"><office:body><office:text><text:h text:outline-level="1">Plan</text:h><text:p>More trees.</text:p></office:text></office:body></office:document-content>')
    end
    expect(described_class.read(upload(buffer.string, "plan.odt"))).to eq("<h1>Plan</h1><p>More trees.</p>")
  end

  it "rejects unsupported or malformed files" do
    expect { described_class.read(upload("invalid", "plan.pdf")) }.to raise_error(described_class::Invalid)
    expect { described_class.read(upload("invalid", "plan.odt")) }.to raise_error(described_class::Invalid)
  end

  it "rejects an oversized file before parsing" do
    expect { described_class.read(upload("a" * (described_class::MAX_UPLOAD + 1), "plan.md")) }.to raise_error(described_class::Invalid)
  end
end
