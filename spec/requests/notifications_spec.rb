require 'rails_helper'

RSpec.describe 'Notifications', type: :request do
  let(:company) { create_company }
  let(:admin) { company_admin(company) }

  def notify(user)
    Notification.create!(user: user, notifiable: company, title: 'Aviso', message: 'Documento por vencer')
  end

  before { sign_in admin }

  it 'marks one notification as read' do
    notification = notify(admin)

    patch mark_as_read_notification_path(notification)

    expect(notification.reload).to be_read
    expect(response).to redirect_to(notifications_path)
  end

  it 'marks all of their notifications as read, and only theirs' do
    mine = [ notify(admin), notify(admin) ]
    others = notify(create_user(:chofer, company: company))

    patch mark_all_as_read_notifications_path

    expect(mine.map(&:reload)).to all(be_read)
    expect(others.reload).not_to be_read
  end

  it 'cannot touch notifications of another user' do
    others = notify(create_user(:chofer, company: company))

    patch mark_as_read_notification_path(others)

    expect(others.reload).not_to be_read
    expect(response).to redirect_to(root_path)
  end
end
