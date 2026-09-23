Rails.application.routes.draw do
  resources :expenses
  resources :work_orders do
    resources :work_order_tasks, only: [:create, :update, :destroy]
    resources :work_order_part_usages, only: [:create, :update, :destroy]
    member do
      patch :change_status
    end
  end
  resources :maintenance_plans do
    resources :maintenance_task_templates, only: [:create, :update, :destroy]
  end
  resources :supply_requests do
    member do
      patch :change_status
    end
  end
  resources :parts
  devise_for :users, skip: [:registrations], controllers: {
    passwords: 'users/passwords',
    sessions: 'users/sessions'
  }

  get  "verificacion",          to: "two_factor#new",    as: :new_two_factor
  post "verificacion",          to: "two_factor#create", as: :two_factor
  post "verificacion/reenviar", to: "two_factor#resend", as: :resend_two_factor

  resources :password_reset_requests, only: [:index, :show, :update]
  resources :companies, only: [:index, :new, :create, :edit, :update, :destroy]
  resources :users do
    resources :user_documents, only: %i[new create edit update destroy]
    resource :force_password_change, only: %i[edit update], module: :users
  end

  resources :alerts, only: [:index]
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
  resources :incidents

  # Auxilio en Ruta: deshabilitado por decisión de producto (con una llamada basta).
  # Código en app/controllers/roadside_assistance_events_controller.rb queda sin usar,
  # no se borró por si se retoma más adelante.
  resources :push_subscriptions, only: [:create]
end
