require 'rails_helper'

RSpec.describe ComplianceChecker do
  let(:company) { create_company }
  let(:vehicle) { create_vehicle(company: company) }

  def document_due(date, status: :ok)
    doc = vehicle.vehicle_documents.new(doc_type: :seguro, due_on: date, status: status)
    doc.file.attach(**pdf_upload)
    doc.save!
    doc
  end

  it 'marks expired documents and notifies the company admins' do
    doc = document_due(Date.current - 1)

    expect { described_class.new.check_all }.to change(Notification, :count).by(1)
    expect(doc.reload).to be_expired

    notification = Notification.last
    expect(notification.user).to eq(admin_of(company))
    expect(notification.title).to eq("Documento Vencido: #{vehicle.plate}")
  end

  it 'marks documents due within 30 days as expiring' do
    doc = document_due(Date.current + 10)

    described_class.new.check_all
    expect(doc.reload).to be_expiring
    expect(Notification.last.title).to start_with('Documento por vencer')
  end

  it 'does not notify twice for a document that was already expired' do
    document_due(Date.current - 1, status: :expired)

    expect { described_class.new.check_all }.not_to change(Notification, :count)
  end

  it 'puts renewed documents back to ok without notifying' do
    doc = document_due(Date.current + 90, status: :expired)

    expect { described_class.new.check_all }.not_to change(Notification, :count)
    expect(doc.reload).to be_ok
  end

  it 'does not notify admins of other companies' do
    other_admin = admin_of(create_company)
    document_due(Date.current - 1)

    described_class.new.check_all
    expect(Notification.where(user: other_admin)).to be_empty
  end
end
