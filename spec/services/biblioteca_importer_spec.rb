require "rails_helper"
require "csv"

RSpec.describe BibliotecaImporter do
  # Copia los CSV reales a una carpeta temporal para poder modificarlos.
  def with_csv_copy
    Dir.mktmpdir do |dir|
      FileUtils.cp(Dir[BibliotecaImporter::DEFAULT_DIR.join("*.csv")], dir)
      yield Pathname(dir)
    end
  end

  def rewrite(file)
    lines = File.read(file, encoding: "bom|utf-8").lines
    File.write(file, yield(lines).join)
  end

  it "loads the whole planilla from db/biblioteca" do
    counts = described_class.new.call

    expect(counts).to eq(modelos: 30, tareas: 28, pasos: 136, plan: 536, repuestos: 371)
  end

  it "keeps the values the app depends on" do
    described_class.new.call

    expect(VehicleModel.find_by!(code: "CAM-01")).to have_attributes(brand: "Mercedes-Benz", meter_unit: "km", base_interval: 30_000)
    expect(VehicleModel.find_by!(code: "MAQ-01").meter_unit).to eq("horas")
    expect(MaintenanceTask.find_by!(code: "TR-01").steps.first.position).to eq(1)
    expect(MaintenanceTask.find_by!(code: "TR-01").estimated_hours).to eq(0.8)
    expect(VehicleModelPlanItem.find_by!(code: "CAM-01-TR-23-INS-D").frequency_unit).to eq("dias")
    expect(VehicleModelPlanItem.find_by!(code: "CAM-01-TR-01-REE-30000")).to have_attributes(frequency_value: 30_000, frequency_unit: "km", frequency_months: 6)
    expect(VehicleModelPart.find_by!(code: "CAM-01-R02")).to have_attributes(unit_price_net_clp: 10_496, quantity: 2, price_type: "verificado")
  end

  it "can run again without duplicating anything" do
    described_class.new.call

    expect { described_class.new.call }.not_to change(VehicleModelPart, :count)
  end

  it "updates changed rows and drops rows that left the planilla" do
    described_class.new.call

    with_csv_copy do |dir|
      rewrite(dir.join("repuestos.csv")) do |lines|
        lines.reject { |line| line.start_with?("CAM-01-R01;") }
             .map { |line| line.start_with?("CAM-01-R02;") ? line.sub(";10496;", ";12000;") : line }
      end
      described_class.new(dir).call
    end

    expect(VehicleModelPart.find_by(code: "CAM-01-R01")).to be_nil
    expect(VehicleModelPart.find_by!(code: "CAM-01-R02").unit_price_net_clp).to eq(12_000)
  end

  it "reads decimals written with a comma by Excel" do
    with_csv_copy do |dir|
      rewrite(dir.join("tareas.csv")) { |lines| lines.map { |line| line.sub(";0.8;", ";0,8;") } }
      described_class.new(dir).call
    end

    expect(MaintenanceTask.find_by!(code: "TR-01").estimated_hours).to eq(0.8)
  end

  it "loads nothing and names the line when a row points to a missing vehicle" do
    with_csv_copy do |dir|
      rewrite(dir.join("plan.csv")) { |lines| lines.map { |line| line.sub(/\ACAM-01-TR-23-INS-D;CAM-01;/, "CAM-01-TR-23-INS-D;CAM-99;") } }

      expect { described_class.new(dir).call }.to raise_error(BibliotecaImporter::Error, /plan\.csv línea 2: no existe el vehículo CAM-99/)
    end

    expect(VehicleModel.count).to eq(0)
  end

  it "says which files are missing" do
    Dir.mktmpdir do |dir|
      expect { described_class.new(dir).call }.to raise_error(BibliotecaImporter::Error, /vehiculos\.csv.*repuestos\.csv/)
    end
  end
end
