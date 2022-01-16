# frozen_string_literal: true

require "spec_helper"
require "./lib/decidim/exporters/word"
require "docx"

module Decidim
  describe Exporters::Word do
    subject { described_class.new(collection, serializer) }

    let(:serializer) do
      Class.new do
        def initialize(resource)
          @resource = resource
        end

        def run
          serialize
        end

        def serialize
          {
            id: @resource.id,
            serialized_name: @resource.name,
            other_ids: @resource.ids,
            float: @resource.float,
            date: @resource.date
          }
        end
      end
    end

    let(:collection) do
      paragraph_component = create(:paragraph_component, :with_amendments_and_participatory_texts_enabled)
      # participatory_text = create(:participatory_text, component: paragraph_component)
      create(:participatory_text, component: paragraph_component)
      paragraph = create(:paragraph, component: paragraph_component)
      Decidim::EnhancedTextwork::Paragraph.where(component: paragraph.component)
      # [
      #   OpenStruct.new(id: 1, name: { ca: "foocat", es: "fooes" }, ids: [1, 2, 3], float: 1.66, date: Time.zone.local(2017, 10, 1, 5, 0)),
      #   OpenStruct.new(id: 2, name: { ca: "barcat", es: "bares" }, ids: [2, 3, 4], float: 0.55, date: Time.zone.local(2017, 9, 20)),
      #   OpenStruct.new(id: 3, name: { ca: "@atcat", es: "@ates" }, ids: [1, 2, 3], float: 0.35, date: Time.zone.local(2020, 7, 20)),
      #   OpenStruct.new(id: 4, name: { ca: "=equalcat", es: "=equales" }, ids: [1, 2, 3], float: 0.45, date: Time.zone.local(2020, 6, 24)),
      #   OpenStruct.new(id: 5, name: { ca: "+pluscat", es: "+pluses" }, ids: [1, 2, 3], float: 0.65, date: Time.zone.local(2020, 7, 15)),
      #   OpenStruct.new(id: 6, name: { ca: "-minuscat", es: "-minuses" }, ids: [1, 2, 3], float: 0.75, date: Time.zone.local(2020, 6, 27))
      # ]
    end

    describe "export" do
      it "successfully exports a docx with multiple paragraphs" do
        exported = StringIO.new(subject.export.read)
        doc = Docx::Document.open(exported)

        expect(doc.paragraphs.count).to be > 10
      end
    end
  end
end
