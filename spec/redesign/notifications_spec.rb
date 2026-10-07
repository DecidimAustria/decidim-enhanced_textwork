# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Textwork notifications" do
  let(:document) { create(:textwork_document, published_at: nil) }
  let(:admin) { create(:user, :admin, :confirmed, organization: document.organization) }
  let(:author) { create(:user, :confirmed, organization: document.organization) }
  let(:follower) { create(:user, :confirmed, organization: document.organization) }
  let(:liker) { create(:user, :confirmed, organization: document.organization) }
  let(:editor) { Decidim::EnhancedTextwork::EditDocument.new(document, admin) }
  let!(:chapter) { editor.add(kind: "heading", body: "Chapter") }
  let!(:block) { editor.add(kind: "paragraph", body: "More trees.") }

  before do
    document.publish!
    Decidim::Follow.create!(followable: document, user: follower)
    Decidim::Like.create!(resource: block, author: liker)
    allow(ActiveRecord).to receive(:after_all_transactions_commit).and_yield
    allow(Decidim::EventsManager).to receive(:publish)
  end

  def suggestion
    result = nil
    Decidim::EnhancedTextwork::SaveSuggestion.call(block, author, body: "Trees and benches.", expected_version: 1) { on(:ok) { |record| result = record } }
    result
  end

  # Exercise preserved notification code independently of the new collection
  # policy. Real admin/command access is covered in collection_lock_spec.
  def allow_retained_evaluation
    allow(document).to receive(:original_editable?).and_return(true)
    document.component.update!(settings: { evaluation_enabled: true })
  end

  it "notifies document followers about a new suggestion" do
    record = suggestion
    expect(Decidim::EventsManager).to have_received(:publish).with(hash_including(event: "decidim.events.textwork.suggestion_created", resource: record, affected_users: [follower]))
  end

  it "notifies author, document followers and likers exactly once after acceptance" do
    allow_retained_evaluation
    record = suggestion
    Decidim::Like.create!(resource: block, author: follower)
    editor.decide(record, decision: "accepted", body: record.original, answer: "", expected_version: 1)
    expect(Decidim::EventsManager).to have_received(:publish).with(hash_including(event: "decidim.events.textwork.suggestion_accepted", affected_users: contain_exactly(author, follower, liker)))
  end

  it "notifies only the author of rejection and escapes the explanation" do
    allow_retained_evaluation
    record = suggestion
    editor.decide(record, decision: "rejected", answer: "Please review <script>unsafe</script>")
    expect(Decidim::EventsManager).to have_received(:publish).with(hash_including(event: "decidim.events.textwork.suggestion_rejected", affected_users: [author]))
    event = Decidim::EnhancedTextwork::ChangeEvent.new(resource: record, user: author, event_name: "decidim.events.textwork.suggestion_rejected")
    expect(event.email_intro).to include("Please review &lt;script&gt;")
    expect(event.notification_title).not_to include("<script>")
  end

  it "notifies followers and likers for editorial changes without a stale-suggestion event" do
    allow_retained_evaluation
    suggestion
    editor.update(block, body: "Many trees.", expected_version: 1)
    expect(Decidim::EventsManager).to have_received(:publish).with(hash_including(event: "decidim.events.textwork.editorial_change", affected_users: contain_exactly(follower, liker)))
    expect(Decidim::EventsManager).not_to have_received(:publish).with(hash_including(event: /outdated|stale/))
  end

  it "uses Core notification hooks for paragraph comments and suggestion authors" do
    expect(block.users_to_notify_on_comment_created).to include(follower)
    expect(suggestion.users_to_notify_on_comment_created).to eq([author])
    comment = Decidim::Comments::Comment.create!(commentable: block, root_commentable: block, author:, body: { en: "Hello" })
    expect(comment.depth).to eq(0)
    Decidim::Comments::NewCommentNotificationCreator.new(comment, []).create
    expect(Decidim::EventsManager).to have_received(:publish).with(hash_including(event: "decidim.events.comments.comment_created", followers: [follower]))
  end

  it "notifies affected followers and pending authors on structural removal" do
    allow_retained_evaluation
    record = suggestion
    editor.remove(block)
    expect(Decidim::EventsManager).to have_received(:publish).with(hash_including(event: "decidim.events.textwork.structure_changed", affected_users: [follower]))
    expect(Decidim::EventsManager).to have_received(:publish).with(hash_including(event: "decidim.events.textwork.suggestion_rejected", resource: record, affected_users: [author]))
  end

  it "notifies document followers for additions and moves" do
    allow_retained_evaluation
    editor.add(kind: "paragraph", body: "Safe roads.")
    editor.add(kind: "heading", body: "Other chapter")
    Decidim::Follow.create!(followable: document, user: author)
    editor.move(block, position: 4)
    expect(Decidim::EventsManager).to have_received(:publish).with(hash_including(event: "decidim.events.textwork.structure_changed", affected_users: contain_exactly(follower, author)))
  end
end
