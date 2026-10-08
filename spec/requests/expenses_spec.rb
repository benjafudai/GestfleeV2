require "rails_helper"

RSpec.describe "Expenses", type: :request do
  let(:company) { create_company }
  let(:admin) { company_admin(company) }
  let!(:expense) do
    Expense.create!(company: company, category: :fuel, amount: 45_000, date: Date.new(2026, 10, 1),
                    provider: "Copec Los Ángeles")
  end

  it "asks to log in first" do
    get expenses_path

    expect(response).to redirect_to(new_user_session_path)
  end

  context "as the company admin" do
    before { sign_in admin }

    it "renders the list" do
      get expenses_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Copec Los Ángeles")
    end

    it "renders the detail" do
      get expense_path(expense)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Copec Los Ángeles")
    end

    it "renders the new form" do
      get new_expense_path

      expect(response).to have_http_status(:ok)
    end

    it "renders the edit form" do
      get edit_expense_path(expense)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Copec Los Ángeles")
    end
  end

  it "doesn't let a chofer see the costs" do
    sign_in create_user(:chofer, company: company)

    get expenses_path

    expect(response).to redirect_to(root_path)
  end

  it "doesn't show an expense from another company" do
    other = create_company(name: "Transportes Dos", rut: "22.222.222-2", admin_email: "admin@dos.cl")
    sign_in company_admin(other)

    get expense_path(expense)

    expect(response).to redirect_to(root_path)
  end
end
