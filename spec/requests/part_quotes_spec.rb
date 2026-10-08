require "rails_helper"

RSpec.describe "Part quotes", type: :request do
  let(:company) { create_company }
  let!(:part) { create_part(company: company, name: "Filtro de aire") }
  let(:params) { { part_quote: { supplier: "Repuestos Sur", price: "18000", currency: "CLP", quoted_on: Date.current.to_s } } }

  it "lets the bodeguero register a quote and shows it on the part" do
    sign_in create_user(:bodeguero, company: company)

    expect { post part_part_quotes_path(part), params: params }.to change(PartQuote, :count).by(1)
    expect(response).to redirect_to(part_path(part))

    follow_redirect!
    expect(response.body).to include("Repuestos Sur")
    expect(response.body).to include("Mejor precio")
  end

  it "explains why an invalid quote wasn't saved" do
    sign_in company_admin(company)

    post part_part_quotes_path(part), params: { part_quote: { supplier: "", price: "0", quoted_on: Date.current.to_s } }

    expect(response).to redirect_to(part_path(part))
    expect(flash[:alert]).to include("Proveedor")
  end

  it "lets the admin delete a quote" do
    quote = PartQuote.create!(part: part, supplier: "X", price: 1, quoted_on: Date.current)
    sign_in company_admin(company)

    expect { delete part_part_quote_path(part, quote) }.to change(PartQuote, :count).by(-1)
  end

  it "doesn't let a mecánico register quotes" do
    sign_in create_user(:mecanico, company: company)

    expect { post part_part_quotes_path(part), params: params }.not_to change(PartQuote, :count)
    expect(response).to redirect_to(root_path)
  end

  it "doesn't let another company add quotes to the part" do
    sign_in company_admin(create_other_company)

    expect { post part_part_quotes_path(part), params: params }.not_to change(PartQuote, :count)
  end
end
