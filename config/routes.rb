FloTestDeploy::Application.routes.draw do
  resources :products

  root to: "pages#home"
end
