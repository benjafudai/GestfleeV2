require "rails_helper"

RSpec.describe WeeklySummarySender do
  let!(:company) { create_company }

  before do
    allow(CurrencyConverter).to receive(:usd_to_clp).and_return(900)
    ActionMailer::Base.deliveries.clear
  end

  it "sends each active company's summary to its admins and extra emails" do
    company.update!(weekly_summary_emails: "gerencia@uno.cl")

    result = described_class.call(today: Date.new(2026, 10, 19))

    expect(result.sent).to eq(["Transportes Uno"])
    expect(ActionMailer::Base.deliveries.sole.to).to eq(["admin@uno.cl", "gerencia@uno.cl"])
  end

  it "skips a company that turned it off" do
    company.update!(weekly_summary_enabled: "0")

    result = described_class.call(today: Date.new(2026, 10, 19))

    expect(result.skipped).to eq(["Transportes Uno"])
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "keeps going when one company fails" do
    other = create_other_company(name: "Zeta")
    allow(WeeklySummaryMailer).to receive(:summary).and_call_original
    allow(WeeklySummaryMailer).to receive(:summary).with(company, anything).and_raise(Net::SMTPAuthenticationError.new("535"))

    result = described_class.call(today: Date.new(2026, 10, 19), logger: Logger.new(nil))

    expect(result.failed).to eq(["Transportes Uno"])
    expect(result.sent).to eq([other.name])
  end
end
