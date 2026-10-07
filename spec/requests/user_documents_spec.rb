require 'rails_helper'

RSpec.describe 'Driver documents', type: :request do
  let(:company) { create_company }
  let(:driver) { create_user(:chofer, company: company) }

  def upload
    uploaded(pdf_file('licencia.pdf'))
  end

  context 'as admin' do
    before { sign_in company_admin(company) }

    it 'adds a document to a driver' do
      expect {
        post user_user_documents_path(driver), params: {
          user_document: { doc_type: 'licencia_conducir', due_on: Date.current + 1.year, file: upload }
        }
      }.to change(UserDocument, :count).by(1)

      document = driver.user_documents.last
      expect(document).to be_ok
      expect(response).to redirect_to(user_path(driver))
    end

    it 'requires a file that is an image or PDF' do
      post user_user_documents_path(driver), params: {
        user_document: { doc_type: 'otro', due_on: Date.current, file: uploaded(text_file('nota.txt')) }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('debe ser una imagen o un PDF')
    end

    it 'updates and deletes a document' do
      document = driver.user_documents.create!(doc_type: :contrato, due_on: Date.current, file: pdf_file)

      patch user_user_document_path(driver, document), params: { user_document: { due_on: Date.current + 30 } }
      expect(document.reload.due_on).to eq(Date.current + 30)

      expect { delete user_user_document_path(driver, document) }.to change(UserDocument, :count).by(-1)
    end

    it 'cannot add documents to a user of another company' do
      outsider = create_user(:chofer, company: create_other_company)

      expect {
        post user_user_documents_path(outsider), params: {
          user_document: { doc_type: 'otro', due_on: Date.current, file: upload }
        }
      }.not_to change(UserDocument, :count)
      expect(response).to redirect_to(root_path)
    end
  end

  it 'does not let a driver manage documents' do
    sign_in driver

    expect {
      post user_user_documents_path(driver), params: { user_document: { doc_type: 'otro', due_on: Date.current, file: upload } }
    }.not_to change(UserDocument, :count)
  end
end
