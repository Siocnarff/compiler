Rails.application.routes.draw do
	root "uploads#index"

	resources :uploads
	get '/process/:id', to: 'process#lex'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
