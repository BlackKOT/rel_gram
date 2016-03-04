module RelGram
  class Engine < ::Rails::Engine
    isolate_namespace RelGram

    initializer 'rel_gram', before: :load_config_initializers do |app|
      Rails.application.routes.prepend do
        mount RelGram::Engine, at: '/rel_gram'
      end
    end
  end
end
