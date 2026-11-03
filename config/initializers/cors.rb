# Only the personal page reads the API from a browser, and only the price list.
# The routes that need the token are opened to no origin.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "https://lucasnestler.github.io", "http://localhost:5500"

    resource "/api/v1/services", methods: [ :get ]
    resource "/api/v1/services/*", methods: [ :get ]
  end
end
