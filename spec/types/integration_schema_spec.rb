# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/component_context"
require "decidim/enhanced_textwork/test/factories"

describe "Decidim::Api::QueryType" do
  include_context "with a graphql decidim component"
  let(:component_type) { "Paragraphs" }
  let!(:current_component) { create :paragraph_component, participatory_space: participatory_process }
  let!(:paragraph) { create(:paragraph, :with_votes, :with_endorsements, :citizen_author, component: current_component, category: category) }
  let!(:amendments) { create_list(:paragraph_amendment, 5, amendable: paragraph, emendation: paragraph) }

  let(:paragraph_single_result) do
    paragraph.reload
    {
      "acceptsNewComments" => paragraph.accepts_new_comments?,
      "address" => paragraph.address,
      "amendments" => paragraph.amendments.map do |a|
        {
          "amendable" => { "id" => a.amendable.id.to_s },
          "amendableType" => a.amendable.class.name,
          "amender" => { "id" => a.amender.id.to_s },
          "emendation" => { "id" => a.emendation.id.to_s },
          "emendationType" => a.emendation.class.name,
          "id" => a.id.to_s,
          "state" => a.state
        }
      end,
      "answer" => nil,
      "answeredAt" => nil,
      "attachments" => [],
      "author" => { "id" => paragraph.authors.first.id.to_s },
      "authors" => paragraph.authors.map { |a| { "id" => a.id.to_s } },
      "authorsCount" => paragraph.authors.size,
      "body" => { "translation" => paragraph.body[locale] },
      "category" => { "id" => paragraph.category.id.to_s },
      "comments" => [],
      "commentsHaveAlignment" => paragraph.comments_have_alignment?,
      "commentsHaveVotes" => paragraph.comments_have_votes?,
      "coordinates" => { "latitude" => paragraph.latitude, "longitude" => paragraph.longitude },
      "createdAt" => paragraph.created_at.iso8601.to_s.gsub("Z", "+00:00"),
      "createdInMeeting" => paragraph.created_in_meeting?,
      "endorsements" => paragraph.endorsements.map do |e|
        { "deleted" => e.author.deleted?,
          "id" => e.author.id.to_s,
          "name" => e.author.name,
          "nickname" => "@#{e.author.nickname}",
          "organizationName" => e.author.organization.name,
          "profilePath" => "/profiles/#{e.author.nickname}" }
      end,
      "endorsementsCount" => paragraph.endorsements.size,
      "fingerprint" => { "source" => paragraph.fingerprint.source, "value" => paragraph.fingerprint.value },
      "hasComments" => paragraph.comment_threads.size.positive?,
      "id" => paragraph.id.to_s,
      "meeting" => nil,
      "official" => paragraph.official?,
      "participatoryTextLevel" => paragraph.participatory_text_level,
      "position" => paragraph.position,
      "publishedAt" => paragraph.published_at.iso8601.to_s.gsub("Z", "+00:00"),
      "reference" => paragraph.reference,
      "scope" => paragraph.scope,
      "state" => paragraph.state,
      "title" => { "translation" => paragraph.title[locale] },
      "totalCommentsCount" => paragraph.comments_count,
      "type" => "Decidim::EnhancedTextwork::Paragraph",
      "updatedAt" => paragraph.updated_at.iso8601.to_s.gsub("Z", "+00:00"),
      "userAllowedToComment" => paragraph.user_allowed_to_comment?(current_user),
      "versions" => [],
      "versionsCount" => 0,
      "voteCount" => paragraph.votes.size
    }
  end

  let(:paragraphs_data) do
    {
      "__typename" => "Paragraphs",
      "id" => current_component.id.to_s,
      "name" => { "translation" => "Paragraphs" },
      "paragraphs" => {
        "edges" => [
          {
            "node" => paragraph_single_result
          }
        ]
      },
      "weight" => 0
    }
  end

  describe "valid connection query" do
    let(:component_fragment) do
      %(
      fragment fooComponent on Paragraphs {
        paragraphs {
          edges{
            node{
              acceptsNewComments
              address
              amendments {
                id
                state
                amender { id }
                amendable { id }
                emendation { id }
                emendationType
                amendableType
              }
              answer {
                translation(locale:"#{locale}")
              }
              answeredAt
              attachments {
                thumbnail
              }
              author {
                id
              }
              authors {
                id
              }
              authorsCount
              body {
                translation(locale:"#{locale}")
              }
              category {
                id
              }
              comments {
                id
              }
              commentsHaveAlignment
              commentsHaveVotes
              coordinates{
                latitude
                longitude
              }
              createdAt
              createdInMeeting
              endorsements {
                id
                deleted
                 name
                nickname
                organizationName
                profilePath
              }
              endorsementsCount
              fingerprint{
                source
                value
              }
              hasComments
              id
              meeting {
                id
              }
              official
              participatoryTextLevel
              position
              publishedAt
              reference
              scope {
                id
              }
              state
              title {
                translation(locale:"#{locale}")
              }
              totalCommentsCount
              type
              updatedAt
              userAllowedToComment
              versions {
                id
                changeset
                createdAt
                editor{
                  id
                }
              }
              versionsCount
              voteCount
            }
          }
        }
      }
    )
    end

    it "executes sucessfully" do
      expect { response }.not_to raise_error
    end
  end

  describe "valid query" do
    let(:component_fragment) do
      %(
      fragment fooComponent on Paragraphs {
        paragraph(id: #{paragraph.id}) {
          acceptsNewComments
          address
          amendments {
            id
            state
            amender { id }
            amendable { id }
            emendation { id }
            emendationType
            amendableType
          }
          answer {
            translation(locale:"#{locale}")
          }
          answeredAt
          attachments {
            thumbnail
          }
          author {
            id
          }
          authors {
            id
          }
          authorsCount
          body {
            translation(locale:"#{locale}")
          }
          category {
            id
          }
          comments {
            id
          }
          commentsHaveAlignment
          commentsHaveVotes
          coordinates{
            latitude
            longitude
          }
          createdAt
          createdInMeeting
          endorsements {
            id
            deleted
             name
            nickname
            organizationName
            profilePath
          }
          endorsementsCount
          fingerprint{
            source
            value
          }
          hasComments
          id
          meeting {
            id
          }
          official
          participatoryTextLevel
          position
          publishedAt
          reference
          scope {
            id
          }
          state
          title {
            translation(locale:"#{locale}")
          }
          totalCommentsCount
          type
          updatedAt
          userAllowedToComment
          versions {
            id
            changeset
            createdAt
            editor{
              id
            }
          }
          versionsCount
          voteCount
        }
      }
    )
    end

    it "executes sucessfully" do
      expect { response }.not_to raise_error
    end

    it do
      expect(response["participatoryProcess"]["components"].first["paragraph"]).to eq(paragraph_single_result)
    end
  end
end
