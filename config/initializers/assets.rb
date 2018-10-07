# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )

# Added by RvB for DHTMLXGrid
Rails.application.config.assets.precompile += %w( dhtmlxgrid.css )
Rails.application.config.assets.precompile += %w( skins/dhtmlxgrid_dhx_skyblue.css )
Rails.application.config.assets.precompile += %w( dhtmlxcommon.js )
Rails.application.config.assets.precompile += %w( dhtmlxgrid.js )
#Rails.application.config.assets.precompile += %w( dhtmlxgridcell.js )
Rails.application.config.assets.precompile += %w( dhtmlxdataprocessor.js )
Rails.application.config.assets.precompile += %w( ext/dhtmlxgrid_filter.js )

