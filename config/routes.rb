Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'pages#home'

  # resources :feeds, only: [:index], :defaults => { :format => 'xml' } do
  #   collection do
  #     get 'ia'
  #     get 'ia_crawlable'
  #   end
  # end

  namespace :feeds do
    resources :ia, only: [:index, :show], :defaults => { :format => 'xml' } do
      member do
        get 'crawlable'
      end
    end

    get 'knowledge_unlatched/all', to: 'knowledge_unlatched#all'

  end
end
