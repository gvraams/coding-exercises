Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  namespace :api do
    namespace :v1 do
      resources :group_events, :only => [:index, :show, :create, :update, :destroy] do
        collection do
          get "count"
        end

        member do
          delete "really_delete"
          put "restore"
          put "publish"
        end
      end
    end
  end
end
