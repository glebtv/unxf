class UnXFRailtie < Rails::Railtie
  initializer "railtie.configure_rails_initialization" do |app|
    app.config.middleware.use UnXF
  end
end
