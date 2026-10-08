require 'rails_helper'

RSpec.describe 'Expense management', type: :request do
  let(:company) { with_modules(create_company, has_analyst: true) }
  let(:vehicle) { create_vehicle(company: company) }

  def create_expense(**attrs)
    Expense.create!(company: company, vehicle: vehicle, category: :tolls, amount: 3_000, currency: 'CLP',
                    date: Date.current, **attrs)
  end

  context 'as admin' do
    before { sign_in company_admin(company) }

    it 'records an expense with a receipt' do
      receipt = uploaded(pdf_file('peaje.pdf'))

      expect {
        post expenses_path, params: {
          expense: { vehicle_id: vehicle.id, category: 'tolls', amount: 4_500, currency: 'CLP',
                     date: Date.current, documents: [ receipt ] }
        }
      }.to change(Expense.unscoped, :count).by(1)

      expense = Expense.unscoped.last
      expect(expense.company).to eq(company)
      expect(expense.documents).to be_attached
      expect(response).to redirect_to(expense_path(expense))
    end

    it 'shows the form again when a receipt is not an image or PDF' do
      file = uploaded(text_file('nota.txt'))

      expect {
        post expenses_path, params: { expense: { category: 'other', amount: 1, currency: 'CLP', date: Date.current,
                                                 documents: [ file ] } }
      }.not_to change(Expense.unscoped, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('debe ser una imagen o un PDF')
    end

    it 'keeps the saved receipts when the expense is edited' do
      expense = create_expense
      expense.documents.attach(pdf_file)

      patch expense_path(expense), params: { expense: { amount: 5_000, documents: [ '' ] } }

      expect(expense.reload.amount).to eq(5_000)
      expect(expense.documents.map { |doc| doc.filename.to_s }).to eq([ 'documento.pdf' ])
    end

    it 'adds new receipts next to the saved ones' do
      expense = create_expense
      expense.documents.attach(pdf_file)
      receipt = uploaded(pdf_file('otra.pdf'))

      patch expense_path(expense), params: { expense: { documents: [ '', receipt ] } }

      expect(expense.reload.documents.map { |doc| doc.filename.to_s }).to contain_exactly('documento.pdf', 'otra.pdf')
    end

    it 'rejects an invalid new receipt on edit and keeps the saved ones' do
      expense = create_expense
      expense.documents.attach(pdf_file)
      file = uploaded(text_file('nota.txt'))

      patch expense_path(expense), params: { expense: { documents: [ file ] } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('documento.pdf')
      expect(expense.reload.documents.map { |doc| doc.filename.to_s }).to eq([ 'documento.pdf' ])
    end

    it 'updates and deletes an expense' do
      expense = create_expense

      patch expense_path(expense), params: { expense: { amount: 9_000 } }
      expect(expense.reload.amount).to eq(9_000)

      expect { delete expense_path(expense) }.to change(Expense.unscoped, :count).by(-1)
      expect(response).to redirect_to(expenses_path)
    end

    it 'shows the form again when the update is invalid' do
      expense = create_expense

      patch expense_path(expense), params: { expense: { amount: -1 } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  context 'as analyst' do
    before { sign_in create_user(:analista, company: company) }

    it 'does not see restricted expenses' do
      restricted = create_expense(restricted_access: true)
      open_expense = create_expense

      get expenses_path
      expect(response.body).to include(expense_path(open_expense))
      expect(response.body).not_to include(expense_path(restricted))

      get expense_path(restricted)
      expect(response).to redirect_to(root_path)
    end

    it 'cannot change expenses' do
      expense = create_expense

      patch expense_path(expense), params: { expense: { amount: 1 } }

      expect(expense.reload.amount).to eq(3_000)
      expect(response).to redirect_to(root_path)
    end
  end
end
