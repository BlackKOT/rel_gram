require "rel_gram/engine"

module RelGram
  class Structure

    def get_structure
      Rails.application.eager_load! unless Rails.configuration.cache_classes
      output_data = ActiveRecord::Base.descendants.each_with_object({tables: {}, rels: {}}) do |model, models_data|
        # begin
        columns = model.columns.each_with_object({}) do |column, columns_data|
          columns_data[column.name] = {type: column.sql_type, null: column.null, default: column.default}
        end
        models_data[:tables][model.name] = {
            attributes: columns,
            external: true,
            parent: model.parent.name
        }

        reflections = model.reflections.each_with_object({}) do |(reflection_name, reflection_object), reflections_data|
          dest_model_name = (reflection_object.options[:class_name] || reflection_name.to_s).singularize.camelize
          through_model = reflection_object.options[:through]
          if through_model.present?
            reflections_data[through_model.to_s.singularize.camelize] = {
                foreign_key: "#{model.name.underscore}_id",
                rel_type: :through
            }
            models_data[:rels][dest_model_name] ||= {}
            models_data[:rels][dest_model_name][through_model.to_s.singularize.camelize] = {
                foreign_key: "#{dest_model_name.underscore}_id",
                rel_type: :through
            }
          end
          reflections_data[dest_model_name] = {
              foreign_key: get_foreign_key(reflection_name, model),
              rel_type: reflection_object.macro,
              alias: reflection_object.options[:class_name].present? ? reflection_name : nil,
              options: reflection_object.options
          }
        end
        models_data[:rels][model.name] = reflections
        # rescue => e
        #   p "Error! #{model} excluded from diagram. #{e.message}"
        # end
      end

      Dir["#{Rails.root}/app/models/**/*.rb"].map do |f|
        begin
          output_data[:tables][f.chomp('.rb').split('/')[-1].singularize.camelize][:external] = false
        rescue => e
          p "Error! Model #{f} not found in models list. #{e.message}"
        end
      end

      output_data

    end

    private
    def get_foreign_key(r_name, model)
      model.reflect_on_association(r_name.to_sym).foreign_key
    end
  end
end
