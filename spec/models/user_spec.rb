require "rails_helper"

RSpec.describe User, type: :model do
  let(:company) { create_company }

  it "needs a company, unless it's a superadmin" do
    chofer = User.new(email: "chofer@test.cl", password: TenantHelpers::SPEC_PASSWORD, role: :chofer)
    superadmin = User.new(email: "super@test.cl", password: TenantHelpers::SPEC_PASSWORD, role: :superadmin)

    expect(chofer).not_to be_valid
    expect(chofer.errors[:company]).to be_present
    expect(superadmin).to be_valid
  end

  it "needs a password of at least 10 characters" do
    user = User.new(email: "chofer@test.cl", password: "Corta-123", role: :chofer, company: company)

    expect(user).not_to be_valid
    expect(user.errors[:password]).to be_present
  end

  it "doesn't allow two accounts with the same email, whatever the case" do
    create_user(:chofer, company: company, email: "chofer@test.cl")
    copy = User.new(email: "CHOFER@test.cl", password: TenantHelpers::SPEC_PASSWORD, role: :chofer, company: company)

    expect(copy).not_to be_valid
    expect(copy.errors[:email]).to be_present
  end

  it "locks the account after 5 failed logins" do
    user = create_user(:chofer, company: company)

    5.times { user.valid_for_authentication? { false } }

    expect(user.reload.access_locked?).to be true
  end
end
