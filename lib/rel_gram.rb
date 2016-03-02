require "rel_gram/engine"

module RelGram
  class Structure

    def get_structure
      Rails.application.eager_load! unless Rails.configuration.cache_classes
      output_data = ActiveRecord::Base.descendants.each_with_object({tables: {}, rels: {}}) do |model, models_data|
        begin
          columns = model.columns.each_with_object({}) do |column, columns_data|
            columns_data[column.name] = {type: column.sql_type, null: column.null, default: column.default}
          end
          models_data[:tables][model.name] = {
            attributes: columns,
            external: true,
            parent: model.parent.name
          }

          reflections = model.reflections.each_with_object({}) do |reflection, reflections_data|
            reflections_data[reflection.last.options[:class_name]||reflection.first.to_s.camelize] = {
                foreign_key: get_foreign_key(reflection, model),
                rel_type: reflection.last.macro,
                alias: reflection.last.options[:class_name].present? ? reflection.first : nil,
                options: reflection.last.options
            }
          end
          models_data[:rels][model.name] = reflections
        rescue => e
          p "Error! #{model} excluded from diagram. #{e.message}"
        end
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
    def get_foreign_key(r, model)
      r.first.respond_to?(:foreign_key) ?
          r.first.foreign_key : r.last.options[:foreign_key] || "#{model.name.underscore}_id"
    end
  end
end
