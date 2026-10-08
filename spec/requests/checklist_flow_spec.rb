require 'rails_helper'

RSpec.describe 'Checklist flow', type: :request do
  let(:company) { create_company }
  let(:vehicle) { create_vehicle(company: company) }
  let(:driver) { create_user(:chofer, company: company) }
  let(:template) do
    ChecklistTemplate.create!(company: company, name: 'Pre-operativo', checklist_items_attributes: [
      { label: 'Luces OK', item_type: :boolean, position: 0, required: true },
      { label: 'Observaciones', item_type: :text, position: 1, required: false }
    ])
  end

  def answers(lights: 'true')
    { '0' => { checklist_item_id: template.checklist_items.first.id, value: lights },
      '1' => { checklist_item_id: template.checklist_items.last.id, value: '' } }
  end

  def submit(**attrs)
    post checklist_submissions_path, params: {
      checklist_submission: { checklist_template_id: template.id, vehicle_id: vehicle.id,
                              checklist_answers_attributes: answers }.merge(attrs)
    }
  end

  describe 'templates (admin)' do
    before { sign_in company_admin(company) }

    it 'creates a template with items, skipping blank rows' do
      expect {
        post checklist_templates_path, params: {
          checklist_template: { name: 'Nocturno', checklist_items_attributes: {
            '0' => { label: 'Balizas', item_type: 'boolean', position: 0, required: '1' },
            '1' => { label: '', item_type: '', position: '', required: '' }
          } }
        }
      }.to change(ChecklistTemplate.unscoped, :count).by(1)

      created = ChecklistTemplate.unscoped.last
      expect(created.company).to eq(company)
      expect(created.checklist_items.map(&:label)).to eq([ 'Balizas' ])
    end

    it 'requires a name' do
      post checklist_templates_path, params: { checklist_template: { name: '' } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'removes an item and deletes the template' do
      item = template.checklist_items.last

      patch checklist_template_path(template), params: {
        checklist_template: { checklist_items_attributes: { '0' => { id: item.id, _destroy: '1' } } }
      }
      expect(template.reload.checklist_items.map(&:label)).to eq([ 'Luces OK' ])

      expect { delete checklist_template_path(template) }.to change(ChecklistTemplate.unscoped, :count).by(-1)
    end
  end

  describe 'daily submission (driver)' do
    before do
      assign_vehicle(driver, vehicle)
      sign_in driver
    end

    it 'sends the checklist of the assigned vehicle' do
      expect { submit }.to change(ChecklistSubmission.unscoped, :count).by(1)

      submission = ChecklistSubmission.unscoped.last
      expect(submission.user).to eq(driver)
      expect(submission.company).to eq(company)
      expect(submission).to be_pending
      expect(submission.checklist_answers.count).to eq(2)
      expect(response).to redirect_to(checklist_submission_path(submission))
    end

    it 'requires an answer for required items' do
      expect {
        submit(checklist_answers_attributes: answers(lights: ''))
      }.not_to change(ChecklistSubmission.unscoped, :count)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('es obligatorio para el ítem')
    end

    it 'only allows one checklist per day' do
      submit

      get new_checklist_submission_path
      expect(response).to redirect_to(checklist_submissions_path)

      expect { submit }.not_to change(ChecklistSubmission.unscoped, :count)
    end

    it 'cannot send a checklist for another vehicle' do
      expect { submit(vehicle_id: create_vehicle(company: company).id) }.not_to change(ChecklistSubmission.unscoped, :count)
    end

    it 'cannot review checklists' do
      submit
      submission = ChecklistSubmission.unscoped.last

      patch review_checklist_submission_path(submission), params: { checklist_submission: { status: 'approved' } }

      expect(submission.reload).to be_pending
    end
  end

  it 'lets an admin approve a checklist' do
    assign_vehicle(driver, vehicle)
    submission = ChecklistSubmission.create!(checklist_template: template, vehicle: vehicle, user: driver)
    sign_in company_admin(company)

    patch review_checklist_submission_path(submission),
          params: { checklist_submission: { status: 'approved', admin_notes: 'Todo bien' } }

    expect(submission.reload).to be_approved
    expect(submission.admin_notes).to eq('Todo bien')
    expect(response).to redirect_to(checklist_submission_path(submission))
  end
end
