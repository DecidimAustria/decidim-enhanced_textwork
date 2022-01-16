# frozen_string_literal: true

require "spec_helper"

module Decidim
  module EnhancedTextwork
    module Admin
      describe UpdateParticipatoryText do
        describe "call" do
          let(:current_component) do
            create(
              :paragraph_component,
              participatory_space: create(:participatory_process)
            )
          end
          let(:paragraphs) do
            paragraphs = create_list(:paragraph, 3, component: current_component)
            paragraphs.each_with_index do |paragraph, idx|
              level = Decidim::EnhancedTextwork::ParticipatoryTextSection::LEVELS.keys[idx]
              paragraph.update(participatory_text_level: level)
              paragraph.versions.destroy_all
            end
            paragraphs
          end
          let(:paragraph_modifications) do
            modifs = []
            new_positions = [3, 1, 2]
            paragraphs.each do |paragraph|
              modifs << Decidim::EnhancedTextwork::Admin::ParticipatoryTextParagraphForm.new(
                id: paragraph.id,
                position: new_positions.shift,
                title: ::Faker::Books::Lovecraft.fhtagn,
                body: { en: ::Faker::Books::Lovecraft.fhtagn(number: 5) }
              ).with_context(
                current_participatory_space: current_component.participatory_space,
                current_component: current_component
              )
            end
            modifs
          end
          let(:form) do
            instance_double(
              PreviewParticipatoryTextForm,
              current_component: current_component,
              paragraphs: paragraph_modifications
            )
          end
          let(:command) { described_class.new(form) }

          it "does not create a version for each paragraph", versioning: true do
            expect { command.call }.to broadcast(:ok)

            paragraphs.each do |paragraph|
              expect(paragraph.reload.versions.count).to be_zero
            end
          end

          describe "when form modifies paragraphs" do
            context "with valid values" do
              it "persists modifications" do
                expect { command.call }.to broadcast(:ok)
                paragraphs.zip(paragraph_modifications).each do |paragraph, paragraph_form|
                  paragraph.reload

                  expect(translated(paragraph_form.title)).to eq translated(paragraph.title)
                  if paragraph.participatory_text_level == Decidim::EnhancedTextwork::ParticipatoryTextSection::LEVELS[:article]
                    expect(translated(paragraph_form.body.stringify_keys)).to eq translated(paragraph.body)
                  end
                  expect(paragraph_form.position).to eq paragraph.position
                end
              end
            end

            context "with invalid values" do
              before do
                paragraph_modifications.each { |paragraph_form| paragraph_form.title = "" }
              end

              it "does not persist modifications and broadcasts invalid" do
                failures = {}
                paragraphs.each do |paragraph|
                  failures[paragraph.id] = ["Title can't be blank"]
                end
                expect { command.call }.to broadcast(:invalid, failures)
              end
            end
          end
        end
      end
    end
  end
end
