# frozen_string_literal: true

require "spec_helper"
RSpec.describe Decidim::EnhancedTextwork::DecideAmendment do
  let!(:amendment) { create(:textwork_amendment) }
  let(:section) { amendment.section }
  let(:admin) { create(:user, :admin, :confirmed, organization: section.organization) }
  it "preserves supported text and creates an unsupported new version" do
    original = section.current_revision
    original.supports.create!(author: amendment.author)
    described_class.call(amendment, admin, "accepted", "Agreed")
    expect(amendment.reload.state).to eq("accepted")
    expect(section.reload.body).to eq(amendment.body)
    expect(section.current_revision).not_to eq(original)
    expect(original.reload.supports.count).to eq(1)
    expect(section.current_revision.supports).to be_empty
    expect(section.document.document_versions.last.snapshot["sections"].first["revision_id"]).to eq(section.current_revision_id)
    expect(amendment.result_revision_id).to eq(section.current_revision_id)
  end
  it "rejects stale competing amendments without changing the current text" do
    competing = create(:textwork_amendment, section:)
    described_class.call(amendment, admin, "accepted", nil)
    expect { described_class.call(competing, admin, "accepted", nil) }.to raise_error(described_class::Conflict)
    expect(competing.reload.state).to eq("pending")
  end
  it "rejects without changing text and records the decision" do
    original = section.current_revision_id
    described_class.call(amendment, admin, "rejected", "Not suitable")
    expect(section.reload.current_revision_id).to eq(original)
    expect(amendment.reload.decision_reason).to eq("Not suitable")
  end
  it "does not let the author decide their own amendment" do
    expect { described_class.call(amendment, amendment.author, "accepted", nil) }.to raise_error(Decidim::ActionForbidden)
  end
  it "does not let an administrator from another organization decide" do
    other = create(:user, :admin)
    expect { described_class.call(amendment, other, "accepted", nil) }.to raise_error(Decidim::ActionForbidden)
  end
  it "prevents decisions being executed twice" do
    described_class.call(amendment, admin, "accepted", nil)
    expect { described_class.call(amendment, admin, "accepted", nil) }.to raise_error(described_class::Conflict)
    expect(section.revisions.count).to eq(2)
  end
  it "does not overwrite a saved revision" do
    expect { section.current_revision.update!(body: { en: "Overwrite" }) }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end
  it "allows the administrator of this participatory process" do
    manager = create(:user, :confirmed, organization: section.organization)
    create(:participatory_process_user_role, user: manager, participatory_process: section.participatory_space, role: :admin)
    described_class.call(amendment, manager, "accepted", nil)
    expect(amendment.reload.state).to eq("accepted")
  end
  it "does not allow an administrator of another participatory process" do
    manager = create(:user, :confirmed, organization: section.organization)
    other_space = create(:participatory_process, organization: section.organization)
    create(:participatory_process_user_role, user: manager, participatory_process: other_space, role: :admin)
    expect { described_class.call(amendment, manager, "accepted", nil) }.to raise_error(Decidim::ActionForbidden)
  end
end
