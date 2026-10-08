require "rails_helper"

RSpec.describe "Part search", type: :request do
  let(:company) { create_company }
  let!(:vehicle) { create_vehicle(company: company, plate: "ABCD12", brand: "Toyota", model: "Hilux", year: 2020) }
  let!(:part) { create_part(company: company, name: "Pastillas de freno", stock: 4) }

  it "asks to log in first" do
    get part_search_path

    expect(response).to redirect_to(new_user_session_path)
  end

  it "shows the empty form" do
    sign_in company_admin(company)

    get part_search_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Buscar repuesto")
  end

  it "finds catalog parts and builds store links with the vehicle data" do
    PartFitment.create!(part: part, vehicle: vehicle)
    PartQuote.create!(part: part, supplier: "Repuestos Sur", price: 25_000, quoted_on: Date.current)
    sign_in create_user(:bodeguero, company: company)

    get part_search_path(q: "freno", vehicle_id: vehicle.id)

    expect(response.body).to include("Pastillas de freno")
    expect(response.body).to include("Compatible con ABCD12")
    expect(response.body).to include("Repuestos Sur")
    expect(response.body).to include("https://listado.mercadolibre.cl/freno-toyota-hilux-2020")
    expect(response.body).to include("https://knasta.cl/results?q=freno%20Toyota%20Hilux%202020")
  end

  it "matches every word, in any order and not necessarily together" do
    create_part(company: company, name: "Filtro de aceite · Original", stock: 2)
    sign_in company_admin(company)

    get part_search_path(q: "aceite filtro")
    expect(response.body).to include("Filtro de aceite · Original")

    get part_search_path(q: "filtro freno")
    expect(response.body).not_to include("Filtro de aceite · Original")
    expect(response.body).not_to include("Pastillas de freno")
  end

  it "doesn't show another company's parts" do
    other = create_other_company
    create_part(company: other, name: "Freno ajeno")
    sign_in company_admin(company)

    get part_search_path(q: "freno")

    expect(response.body).to include("Pastillas de freno")
    expect(response.body).not_to include("Freno ajeno")
  end

  it "treats % and _ in the search as plain text" do
    sign_in company_admin(company)

    get part_search_path(q: "%")

    expect(response.body).not_to include("Pastillas de freno")
  end

  it "doesn't let a chofer in" do
    sign_in create_user(:chofer, company: company)

    get part_search_path

    expect(response).to redirect_to(root_path)
  end
end
