# frozen_string_literal: true

require "decidim/components/namer"

Decidim.register_component(:enhanced_textwork) do |component|
  component.engine = Decidim::EnhancedTextwork::Engine
  component.admin_engine = Decidim::EnhancedTextwork::AdminEngine
  component.stylesheet = "decidim/enhanced_textwork/paragraphs"
  component.icon = "media/images/decidim_enhanced_textwork.svg"

  component.on(:before_destroy) do |instance|
    raise "Can't destroy this component when there are paragraphs" if Decidim::EnhancedTextwork::Paragraph.where(component: instance).any?
  end

  component.data_portable_entities = ["Decidim::EnhancedTextwork::Paragraph"]

  component.newsletter_participant_entities = ["Decidim::EnhancedTextwork::Paragraph"]

  component.actions = %w(endorse vote create withdraw amend comment vote_comment)

  component.query_type = "Decidim::EnhancedTextwork::ParagraphsType"

  component.permissions_class_name = "Decidim::EnhancedTextwork::Permissions"

  ENHANCED_TEXTWORK_POSSIBLE_SORT_ORDERS = %w(default random recent most_endorsed most_voted most_commented most_followed with_more_authors).freeze

  component.settings(:global) do |settings|
    settings.attribute :scopes_enabled, type: :boolean, default: false
    settings.attribute :scope_id, type: :scope
    settings.attribute :vote_limit, type: :integer, default: 0
    settings.attribute :minimum_votes_per_user, type: :integer, default: 0
    settings.attribute :paragraph_limit, type: :integer, default: 0
    settings.attribute :paragraph_length, type: :integer, default: 500
    settings.attribute :paragraph_edit_time, type: :enum, default: "limited", choices: -> { %w(limited infinite) }
    settings.attribute :paragraph_edit_before_minutes, type: :integer, default: 5
    settings.attribute :threshold_per_paragraph, type: :integer, default: 0
    settings.attribute :can_accumulate_supports_beyond_threshold, type: :boolean, default: false
    settings.attribute :paragraph_answering_enabled, type: :boolean, default: true
    settings.attribute :default_sort_order, type: :select, default: "default", choices: -> { ENHANCED_TEXTWORK_POSSIBLE_SORT_ORDERS }
    settings.attribute :official_paragraphs_enabled, type: :boolean, default: true
    settings.attribute :comments_enabled, type: :boolean, default: true
    settings.attribute :comments_max_length, type: :integer, required: false
    settings.attribute :geocoding_enabled, type: :boolean, default: false
    settings.attribute :attachments_allowed, type: :boolean, default: false
    settings.attribute :resources_permissions_enabled, type: :boolean, default: true
    settings.attribute :collaborative_drafts_enabled, type: :boolean, default: false
    settings.attribute :participatory_texts_enabled,
                       type: :boolean, default: true,
                       readonly: ->(context) { Decidim::EnhancedTextwork::Paragraph.where(component: context[:component]).any? }
    settings.attribute :hide_participatory_text_titles_enabled, type: :boolean, default: true
    settings.attribute :amendments_enabled, type: :boolean, default: true
    settings.attribute :amendments_wizard_help_text, type: :text, translated: true, editor: true, required: false
    settings.attribute :announcement, type: :text, translated: true, editor: true
    settings.attribute :new_paragraph_body_template, type: :text, translated: true, editor: true, required: false
    settings.attribute :new_paragraph_help_text, type: :text, translated: true, editor: true
    settings.attribute :paragraph_wizard_step_1_help_text, type: :text, translated: true, editor: true
    settings.attribute :paragraph_wizard_step_2_help_text, type: :text, translated: true, editor: true
    settings.attribute :paragraph_wizard_step_3_help_text, type: :text, translated: true, editor: true
    settings.attribute :paragraph_wizard_step_4_help_text, type: :text, translated: true, editor: true
  end

  component.settings(:step) do |settings|
    settings.attribute :endorsements_enabled, type: :boolean, default: true
    settings.attribute :endorsements_blocked, type: :boolean
    settings.attribute :votes_enabled, type: :boolean
    settings.attribute :votes_blocked, type: :boolean
    settings.attribute :votes_hidden, type: :boolean, default: false
    settings.attribute :comments_blocked, type: :boolean, default: false
    settings.attribute :creation_enabled, type: :boolean
    settings.attribute :paragraph_answering_enabled, type: :boolean, default: true
    settings.attribute :default_sort_order, type: :select, include_blank: true, choices: -> { ENHANCED_TEXTWORK_POSSIBLE_SORT_ORDERS }
    settings.attribute :publish_answers_immediately, type: :boolean, default: true
    settings.attribute :answers_with_costs, type: :boolean, default: false
    settings.attribute :amendment_creation_enabled, type: :boolean, default: true
    settings.attribute :amendment_reaction_enabled, type: :boolean, default: true
    settings.attribute :amendment_promotion_enabled, type: :boolean, default: true
    settings.attribute :amendments_visibility,
                       type: :enum, default: "all",
                       choices: -> { Decidim.config.amendments_visibility_options }
    settings.attribute :announcement, type: :text, translated: true, editor: true
    settings.attribute :automatic_hashtags, type: :text, editor: false, required: false
    settings.attribute :suggested_hashtags, type: :text, editor: false, required: false
  end

  component.register_resource(:paragraph) do |resource|
    resource.model_class_name = "Decidim::EnhancedTextwork::Paragraph"
    resource.template = "decidim/enhanced_textwork/paragraphs/linked_paragraphs"
    resource.card = "decidim/enhanced_textwork/paragraph"
    resource.reported_content_cell = "decidim/enhanced_textwork/reported_content"
    resource.actions = %w(endorse vote amend comment vote_comment)
    resource.searchable = true
  end

  component.register_resource(:collaborative_draft) do |resource|
    resource.model_class_name = "Decidim::EnhancedTextwork::CollaborativeDraft"
    resource.card = "decidim/enhanced_textwork/collaborative_draft"
    resource.reported_content_cell = "decidim/enhanced_textwork/collaborative_drafts/reported_content"
  end

  component.register_stat :paragraphs_count, primary: true, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |components, start_at, end_at|
    Decidim::EnhancedTextwork::FilteredParagraphs.for(components, start_at, end_at).published.except_withdrawn.not_hidden.count
  end

  component.register_stat :paragraphs_accepted, primary: true, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |components, start_at, end_at|
    Decidim::EnhancedTextwork::FilteredParagraphs.for(components, start_at, end_at).accepted.not_hidden.count
  end

  component.register_stat :supports_count, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |components, start_at, end_at|
    paragraphs = Decidim::EnhancedTextwork::FilteredParagraphs.for(components, start_at, end_at).published.not_hidden
    Decidim::EnhancedTextwork::ParagraphVote.where(paragraph: paragraphs).count
  end

  component.register_stat :endorsements_count, priority: Decidim::StatsRegistry::MEDIUM_PRIORITY do |components, start_at, end_at|
    paragraphs = Decidim::EnhancedTextwork::FilteredParagraphs.for(components, start_at, end_at).not_hidden
    paragraphs.sum(:endorsements_count)
  end

  component.register_stat :comments_count, tag: :comments do |components, start_at, end_at|
    paragraphs = Decidim::EnhancedTextwork::FilteredParagraphs.for(components, start_at, end_at).published.not_hidden
    paragraphs.sum(:comments_count)
  end

  component.register_stat :followers_count, tag: :followers, priority: Decidim::StatsRegistry::LOW_PRIORITY do |components, start_at, end_at|
    paragraphs_ids = Decidim::EnhancedTextwork::FilteredParagraphs.for(components, start_at, end_at).published.not_hidden.pluck(:id)
    Decidim::Follow.where(decidim_followable_type: "Decidim::EnhancedTextwork::Paragraph", decidim_followable_id: paragraphs_ids).count
  end

  component.exports :paragraphs do |exports|
    exports.collection do |component_instance, user|
      space = component_instance.participatory_space

      collection = Decidim::EnhancedTextwork::Paragraph
                   .published
                   .where(component: component_instance)
                   .includes(:category, :component)

      if space.user_roles(:valuator).where(user: user).any?
        collection.with_valuation_assigned_to(user, space)
      else
        collection
      end
    end

    exports.formats %w(CSV JSON Excel Word)

    exports.include_in_open_data = true

    exports.serializer Decidim::EnhancedTextwork::ParagraphSerializer
  end

  component.exports :paragraph_comments do |exports|
    exports.collection do |component_instance|
      Decidim::Comments::Export.comments_for_resource(
        Decidim::EnhancedTextwork::Paragraph, component_instance
      )
    end

    exports.include_in_open_data = true

    exports.serializer Decidim::Comments::CommentSerializer
  end

  component.imports :paragraphs do |imports|
    imports.creator Decidim::EnhancedTextwork::ParagraphCreator
  end

  component.seeds do |participatory_space|
    admin_user = Decidim::User.find_by(
      organization: participatory_space.organization,
      email: "admin@example.org"
    )

    step_settings = if participatory_space.allows_steps?
                      { participatory_space.active_step.id => { votes_enabled: true, votes_blocked: false, creation_enabled: true } }
                    else
                      {}
                    end

    params = {
      name: Decidim::Components::Namer.new(participatory_space.organization.available_locales, :paragraphs).i18n_name,
      manifest_name: :enhanced_textwork,
      published_at: Time.current,
      participatory_space: participatory_space,
      settings: {
        vote_limit: 0,
        collaborative_drafts_enabled: true
      },
      step_settings: step_settings
    }

    component = Decidim.traceability.perform_action!(
      "publish",
      Decidim::Component,
      admin_user,
      visibility: "all"
    ) do
      Decidim::Component.create!(params)
    end

    if participatory_space.scope
      scopes = participatory_space.scope.descendants
      global = participatory_space.scope
    else
      scopes = participatory_space.organization.scopes
      global = nil
    end

    5.times do |n|
      state, answer, state_published_at = if n > 3
                                            ["accepted", Decidim::Faker::Localized.sentence(word_count: 10), Time.current]
                                          elsif n > 2
                                            ["rejected", nil, Time.current]
                                          elsif n > 1
                                            ["evaluating", nil, Time.current]
                                          elsif n.positive?
                                            ["accepted", Decidim::Faker::Localized.sentence(word_count: 10), nil]
                                          else
                                            [nil, nil, nil]
                                          end

      params = {
        component: component,
        category: participatory_space.categories.sample,
        scope: Faker::Boolean.boolean(true_ratio: 0.5) ? global : scopes.sample,
        title: { en: Faker::Lorem.sentence(word_count: 2) },
        body: { en: Faker::Lorem.paragraphs(number: 2).join("\n") },
        state: state,
        answer: answer,
        answered_at: state.present? ? Time.current : nil,
        state_published_at: state_published_at,
        published_at: Time.current
      }

      paragraph = Decidim.traceability.perform_action!(
        "publish",
        Decidim::EnhancedTextwork::Paragraph,
        admin_user,
        visibility: "all"
      ) do
        paragraph = Decidim::EnhancedTextwork::Paragraph.new(params)
        coauthor =  case n
                    when 0
                      Decidim::User.where(decidim_organization_id: participatory_space.decidim_organization_id).order(Arel.sql("RANDOM()")).first
                    when 1
                      Decidim::UserGroup.where(decidim_organization_id: participatory_space.decidim_organization_id).order(Arel.sql("RANDOM()")).first
                    else
                      participatory_space.organization
                    end
        paragraph.add_coauthor(coauthor)
        paragraph.save!
        paragraph
      end

      if paragraph.state.nil?
        email = "amendment-author-#{participatory_space.underscored_name}-#{participatory_space.id}-#{n}-amend#{n}@example.org"
        name = "#{Faker::Name.name} #{participatory_space.id} #{n} amend#{n}"

        author = Decidim::User.find_or_initialize_by(email: email)
        author.update!(
          password: "Si0thae4hahf5jai",
          password_confirmation: "Si0thae4hahf5jai",
          name: name,
          nickname: Faker::Twitter.unique.screen_name,
          organization: component.organization,
          tos_agreement: "1",
          confirmed_at: Time.current
        )

        group = Decidim::UserGroup.create!(
          name: Faker::Name.name,
          nickname: Faker::Twitter.unique.screen_name,
          email: Faker::Internet.email,
          extended_data: {
            document_number: Faker::Code.isbn,
            phone: Faker::PhoneNumber.phone_number,
            verified_at: Time.current
          },
          decidim_organization_id: component.organization.id,
          confirmed_at: Time.current
        )

        Decidim::UserGroupMembership.create!(
          user: author,
          role: "creator",
          user_group: group
        )

        params = {
          component: component,
          category: participatory_space.categories.sample,
          scope: Faker::Boolean.boolean(true_ratio: 0.5) ? global : scopes.sample,
          title: { en: "#{paragraph.title["en"]} #{Faker::Lorem.sentence(word_count: 1)}" },
          body: { en: "#{paragraph.body["en"]} #{Faker::Lorem.sentence(word_count: 3)}" },
          state: "evaluating",
          answer: nil,
          answered_at: Time.current,
          published_at: Time.current
        }

        emendation = Decidim.traceability.perform_action!(
          "create",
          Decidim::EnhancedTextwork::Paragraph,
          author,
          visibility: "public-only"
        ) do
          emendation = Decidim::EnhancedTextwork::Paragraph.new(params)
          emendation.add_coauthor(author, user_group: author.user_groups.first)
          emendation.save!
          emendation
        end

        Decidim::Amendment.create!(
          amender: author,
          amendable: paragraph,
          emendation: emendation,
          state: "evaluating"
        )
      end

      (n % 3).times do |m|
        email = "vote-author-#{participatory_space.underscored_name}-#{participatory_space.id}-#{n}-#{m}@example.org"
        name = "#{Faker::Name.name} #{participatory_space.id} #{n} #{m}"

        author = Decidim::User.find_or_initialize_by(email: email)
        author.update!(
          password: "Si0thae4hahf5jai",
          password_confirmation: "Si0thae4hahf5jai",
          name: name,
          nickname: Faker::Twitter.unique.screen_name,
          organization: component.organization,
          tos_agreement: "1",
          confirmed_at: Time.current,
          personal_url: Faker::Internet.url,
          about: Faker::Lorem.paragraph(sentence_count: 2)
        )

        Decidim::EnhancedTextwork::ParagraphVote.create!(paragraph: paragraph, author: author) unless paragraph.published_state? && paragraph.rejected?
        Decidim::EnhancedTextwork::ParagraphVote.create!(paragraph: emendation, author: author) if emendation
      end

      unless paragraph.published_state? && paragraph.rejected?
        (n * 2).times do |index|
          email = "endorsement-author-#{participatory_space.underscored_name}-#{participatory_space.id}-#{n}-endr#{index}@example.org"
          name = "#{Faker::Name.name} #{participatory_space.id} #{n} endr#{index}"

          author = Decidim::User.find_or_initialize_by(email: email)
          author.update!(
            password: "Si0thae4hahf5jai",
            password_confirmation: "Si0thae4hahf5jai",
            name: name,
            nickname: Faker::Twitter.unique.screen_name,
            organization: component.organization,
            tos_agreement: "1",
            confirmed_at: Time.current
          )
          if index.even?
            group = Decidim::UserGroup.create!(
              name: Faker::Name.name,
              nickname: Faker::Twitter.unique.screen_name,
              email: Faker::Internet.email,
              extended_data: {
                document_number: Faker::Code.isbn,
                phone: Faker::PhoneNumber.phone_number,
                verified_at: Time.current
              },
              decidim_organization_id: component.organization.id,
              confirmed_at: Time.current
            )

            Decidim::UserGroupMembership.create!(
              user: author,
              role: "creator",
              user_group: group
            )
          end
          Decidim::Endorsement.create!(resource: paragraph, author: author, user_group: author.user_groups.first)
        end
      end

      (n % 3).times do
        author_admin = Decidim::User.where(organization: component.organization, admin: true).all.sample

        Decidim::EnhancedTextwork::ParagraphNote.create!(
          paragraph: paragraph,
          author: author_admin,
          body: Faker::Lorem.paragraphs(number: 2).join("\n")
        )
      end

      Decidim::Comments::Seed.comments_for(paragraph)

      #
      # Collaborative drafts
      #
      state = if n > 3
                "published"
              elsif n > 2
                "withdrawn"
              else
                "open"
              end
      author = Decidim::User.where(organization: component.organization).all.sample

      draft = Decidim.traceability.perform_action!("create", Decidim::EnhancedTextwork::CollaborativeDraft, author) do
        draft = Decidim::EnhancedTextwork::CollaborativeDraft.new(
          component: component,
          category: participatory_space.categories.sample,
          scope: Faker::Boolean.boolean(true_ratio: 0.5) ? global : scopes.sample,
          title: Faker::Lorem.sentence(word_count: 2),
          body: Faker::Lorem.paragraphs(number: 2).join("\n"),
          state: state,
          published_at: Time.current
        )
        draft.coauthorships.build(author: participatory_space.organization)
        draft.save!
        draft
      end

      case n
      when 2
        author2 = Decidim::User.where(organization: component.organization).all.sample
        Decidim::Coauthorship.create(coauthorable: draft, author: author2)
        author3 = Decidim::User.where(organization: component.organization).all.sample
        Decidim::Coauthorship.create(coauthorable: draft, author: author3)
        author4 = Decidim::User.where(organization: component.organization).all.sample
        Decidim::Coauthorship.create(coauthorable: draft, author: author4)
        author5 = Decidim::User.where(organization: component.organization).all.sample
        Decidim::Coauthorship.create(coauthorable: draft, author: author5)
        author6 = Decidim::User.where(organization: component.organization).all.sample
        Decidim::Coauthorship.create(coauthorable: draft, author: author6)
      when 3
        author2 = Decidim::User.where(organization: component.organization).all.sample
        Decidim::Coauthorship.create(coauthorable: draft, author: author2)
      end

      Decidim::Comments::Seed.comments_for(draft)
    end

    Decidim.traceability.update!(
      Decidim::EnhancedTextwork::CollaborativeDraft.all.sample,
      Decidim::User.where(organization: component.organization).all.sample,
      component: component,
      category: participatory_space.categories.sample,
      scope: Faker::Boolean.boolean(true_ratio: 0.5) ? global : scopes.sample,
      title: Faker::Lorem.sentence(word_count: 2),
      body: Faker::Lorem.paragraphs(number: 2).join("\n")
    )
  end
end
