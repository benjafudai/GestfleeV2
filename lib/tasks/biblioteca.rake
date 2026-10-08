namespace :biblioteca do
  desc "Carga la biblioteca común de mantención desde CSV (por defecto db/biblioteca). Uso: rails \"biblioteca:importar[carpeta]\""
  task :importar, [:dir] => :environment do |_task, args|
    counts = BibliotecaImporter.new(args[:dir].presence || BibliotecaImporter::DEFAULT_DIR).call
    puts "Biblioteca cargada: " + counts.map { |name, count| "#{count} #{name}" }.join(", ")
  rescue BibliotecaImporter::Error => e
    abort "No se cargó nada: #{e.message}"
  end
end
