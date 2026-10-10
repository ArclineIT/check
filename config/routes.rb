Rails.application.routes.draw do
  root "checks#new"

  get "check", to: "checks#show", as: :check

  # Health check for load balancers and uptime monitors.
  get "up" => "rails/health#show", as: :rails_health_check
end
