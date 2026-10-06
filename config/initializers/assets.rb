# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
Rails.application.config.assets.paths << Rails.root.join("node_modules/bootstrap-icons/font")

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )
Rails.application.config.assets.precompile += %w( gestflee.css )

# En Windows el caché en disco de Sprockets (tmp/cache/assets) falla cuando dos
# peticiones compilan el mismo asset a la vez: Windows no deja renombrar un
# archivo que otro proceso tiene abierto (Errno::EACCES en File.rename) y la
# página responde 500. Ahí se usa un caché en memoria; en Linux (producción)
# se mantiene el caché en disco.
if Gem.win_platform?
  Rails.application.config.assets.configure do |env|
    env.cache = Sprockets::Cache::MemoryStore.new
  end
end
