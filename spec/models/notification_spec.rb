require "rails_helper"

RSpec.describe Notification, type: :model do
  let(:company) { create_company }
  let(:admin) { company_admin(company) }

  def notification
    Notification.create!(user: admin, notifiable: company, title: "Aviso", message: "Algo pasó")
  end

  it "needs a title and a message" do
    expect(Notification.new(user: admin, notifiable: company)).not_to be_valid
  end

  it "starts unread and can be marked as read" do
    record = notification

    expect(record).not_to be_read
    record.mark_as_read!
    expect(record.reload).to be_read
  end

  it "splits read and unread notifications" do
    unread = notification
    read = notification.tap(&:mark_as_read!)

    expect(Notification.unread).to contain_exactly(unread)
    expect(Notification.read).to contain_exactly(read)
  end
end
