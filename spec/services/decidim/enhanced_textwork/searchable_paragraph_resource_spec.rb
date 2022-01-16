# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe Search do
    subject { described_class.new(params) }

    include_context "when a resource is ready for global search"

    let(:participatory_space) { create(:participatory_process, :published, :with_steps, organization: organization) }
    let(:current_component) { create :paragraph_component, organization: organization, participatory_space: participatory_space }
    let!(:paragraph) do
      create(
        :paragraph,
        :draft,
        skip_injection: true,
        component: current_component,
        scope: scope1,
        body: description_1,
        users: [author]
      )
    end

    describe "Indexing of paragraphs" do
      context "when implementing Searchable" do
        context "when on create" do
          context "when paragraphs are NOT official" do
            let(:paragraph2) do
              create(:paragraph, skip_injection: true, component: current_component)
            end

            it "does not index a SearchableResource after Paragraph creation when it is not official" do
              searchables = SearchableResource.where(resource_type: paragraph.class.name, resource_id: [paragraph.id, paragraph2.id])
              expect(searchables).to be_empty
            end
          end

          context "when paragraphs ARE official" do
            let(:author) { organization }

            before do
              paragraph.update(published_at: Time.current)
            end

            it "does indexes a SearchableResource after Paragraph creation when it is official" do
              organization.available_locales.each do |locale|
                searchable = SearchableResource.find_by(resource_type: paragraph.class.name, resource_id: paragraph.id, locale: locale)
                expect_searchable_resource_to_correspond_to_paragraph(searchable, paragraph, locale)
              end
            end
          end
        end

        context "when on update" do
          context "when it is NOT published" do
            it "does not index a SearchableResource when Paragraph changes but is not published" do
              searchables = SearchableResource.where(resource_type: paragraph.class.name, resource_id: paragraph.id)
              expect(searchables).to be_empty
            end
          end

          context "when it IS published" do
            before do
              paragraph.update published_at: Time.current
            end

            it "inserts a SearchableResource after Paragraph is published" do
              organization.available_locales.each do |locale|
                searchable = SearchableResource.find_by(resource_type: paragraph.class.name, resource_id: paragraph.id, locale: locale)
                expect_searchable_resource_to_correspond_to_paragraph(searchable, paragraph, locale)
              end
            end

            it "updates the associated SearchableResource after published Paragraph update" do
              searchable = SearchableResource.find_by(resource_type: paragraph.class.name, resource_id: paragraph.id)
              created_at = searchable.created_at
              updated_title = { "en" => "Brand new title", "machine_translations" => {} }
              paragraph.update(title: updated_title)

              paragraph.save!
              searchable.reload

              organization.available_locales.each do |locale|
                searchable = SearchableResource.find_by(resource_type: paragraph.class.name, resource_id: paragraph.id, locale: locale)
                expect(searchable.content_a).to eq updated_title[locale.to_s].to_s
                expect(searchable.updated_at).to be > created_at
              end
            end

            it "removes the associated SearchableResource after unpublishing a published Paragraph on update" do
              paragraph.update(published_at: nil)

              searchables = SearchableResource.where(resource_type: paragraph.class.name, resource_id: paragraph.id)
              expect(searchables).to be_empty
            end
          end
        end

        context "when on destroy" do
          it "destroys the associated SearchableResource after Paragraph destroy" do
            paragraph.destroy

            searchables = SearchableResource.where(resource_type: paragraph.class.name, resource_id: paragraph.id)

            expect(searchables.any?).to be false
          end
        end
      end
    end

    describe "Search" do
      context "when searching by Paragraph resource_type" do
        let!(:paragraph2) do
          create(
            :paragraph,
            component: current_component,
            scope: scope1,
            title: Decidim::Faker.name,
            body: "Chewie, I'll be waiting for your signal. Take care, you two. May the Force be with you. Ow!"
          )
        end

        before do
          paragraph.update(published_at: Time.current)
          paragraph2.update(published_at: Time.current)
        end

        it "returns Paragraph results" do
          Decidim::Search.call("Ow", organization, resource_type: paragraph.class.name) do
            on(:ok) do |results_by_type|
              results = results_by_type[paragraph.class.name]
              expect(results[:count]).to eq 2
              expect(results[:results]).to match_array [paragraph, paragraph2]
            end
            on(:invalid) { raise("Should not happen") }
          end
        end

        it "allows searching by prefix characters" do
          Decidim::Search.call("wait", organization, resource_type: paragraph.class.name) do
            on(:ok) do |results_by_type|
              results = results_by_type[paragraph.class.name]
              expect(results[:count]).to eq 1
              expect(results[:results]).to eq [paragraph2]
            end
            on(:invalid) { raise("Should not happen") }
          end
        end
      end
    end

    private

    def expect_searchable_resource_to_correspond_to_paragraph(searchable, paragraph, locale)
      attrs = searchable.attributes.clone
      attrs.delete("id")
      attrs.delete("created_at")
      attrs.delete("updated_at")
      expect(attrs.delete("datetime").to_s(:short)).to eq(paragraph.published_at.to_s(:short))
      expect(attrs).to eq(expected_searchable_resource_attrs(paragraph, locale))
    end

    def expected_searchable_resource_attrs(paragraph, locale)
      {
        "content_a" => I18n.transliterate(translated(paragraph.title, locale: locale)),
        "content_b" => "",
        "content_c" => "",
        "content_d" => I18n.transliterate(translated(paragraph.body, locale: locale)),
        "locale" => locale,
        "decidim_organization_id" => paragraph.component.organization.id,
        "decidim_participatory_space_id" => current_component.participatory_space_id,
        "decidim_participatory_space_type" => current_component.participatory_space_type,
        "decidim_scope_id" => paragraph.decidim_scope_id,
        "resource_id" => paragraph.id,
        "resource_type" => "Decidim::EnhancedTextwork::Paragraph"
      }
    end
  end
end
