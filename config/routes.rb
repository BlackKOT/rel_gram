RelGram::Engine.routes.draw do
  get '/rel_diagram', to: 'rel_gram#index', as: 'rel_diagram'
end
