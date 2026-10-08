Rails.application.routes.draw do
  resources :expenses
  resources :work_orders do
    member do
      patch :change_status
    end
  end
  resources :maintenance_plans
  resources :supply_requests do
    member do
      patch :change_status
    end
  end
  resources :parts do
    resources :part_quotes, only: %i[create destroy]
  end
  resource :part_search, only: :show, path: "buscar_repuestos"
  devise_for :users, controllers: {
    passwords: 'users/passwords'
  }

  resources :password_reset_requests, only: [:index, :show, :update] do
    patch :reject, on: :member
  end
  resources :companies, only: [:index, :new, :create, :edit, :update, :destroy]
  resources :users do
    patch :unlock, on: :member
    resources :user_documents, only: %i[new create edit update destroy]
    resource :force_password_change, only: %i[edit update], module: :users
  end

  resources :alerts, only: [:index]
  resources :failure_analytics, only: [:index]
  resources :notifications, only: [:index] do
    member do
      patch :mark_as_read
    end
    collection do
      patch :mark_all_as_read
    end
  end

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Root → login si no autenticado, dashboard si autenticado
  root "dashboards#show"
  get "/dashboard", to: "dashboards#show"

  # Sprint 1: flota + documentos + asignaciones
  resources :vehicles do
    resources :vehicle_documents, only: %i[new create edit update destroy]
    resources :vehicle_assignments, only: %i[new create destroy]
    resources :fuel_fills, only: %i[new create index]
    post :generate_plan, on: :member
  end

  resources :fuel_fills, only: %i[index show edit update destroy]

  # Sprint 2: Checklists pre-operativos + Auditoría de inspecciones
  resources :checklist_templates

  resources :checklist_submissions, only: %i[index new create show] do
    member do
      patch :review
    end
  end

  # Sprint 3: Evidencias e Incidentes
  resources :incidents, except: :destroy

  # Auxilio en Ruta: deshabilitado por decisión de producto (con una llamada basta).
  # Código en app/controllers/roadside_assistance_events_controller.rb queda sin usar,
  # no se borró por si se retoma más adelante.
  resources :push_subscriptions, only: [:create]
end
