require "rel_gram/engine"

module RelGram
  class Structure

    def get_structure
      Rails.application.eager_load! unless Rails.configuration.cache_classes
      output_data = ActiveRecord::Base.descendants.each_with_object({tables: {}, rels: {}}) do |model, models_data|
        begin
          columns = get_columns(model)
          models_data[:tables][model.name] = {attributes: columns, external: true, parent: model.parent.name}
          reflections = get_reflections(model, models_data)
          models_data[:rels][model.name] = reflections
        rescue => e
          p "Error! #{model} excluded from diagram. #{e.message}"
        end
      end

      Dir["#{Rails.root}/app/models/**/*.rb"].map do |f|
        begin
          output_data[:tables][to_name(f.chomp('.rb').split('/')[-1], true)][:external] = false
        rescue => e
          p "Error! Model #{f} not found in models list. #{e.message} #{e.backtrace}"
        end
      end

      output_data

    end

    private

    def get_columns(model)
      model.columns.each_with_object({}) do |column, columns_data|
        columns_data[column.name] = {type: column.sql_type, null: column.null, default: convert_default(column.default)}
      end
    end

    def get_reflections(model, models_data)
      reflections = model.reflections.each_with_object({}) do |(reflection_name, reflection_object), reflections_data|
        dest_model_name = to_name(reflection_object.options[:class_name] || reflection_name)
        dest_model_name = to_name(dest_model_name, true) unless reflection_object.macro == :belongs_to
        through_model = reflection_object.options[:through]
        if through_model.present?
          reflections_data[to_name(through_model, true)] = {key: "#{model.name.underscore}_id", rel_type: :through}
          models_data[:rels][dest_model_name] ||= {}
          models_data[:rels][dest_model_name][to_name(through_model, true)] = {
              key: "#{dest_model_name.underscore}_id",
              rel_type: :through
          }
        else
          unless models_data[:rels][model.name].try(:[], dest_model_name).try(:[], :rel_type) == :through
            as_model = reflection_object.options[:as]
            if as_model.present?
              models_data[:tables][to_name(as_model)] ||= []
              models_data[:tables][to_name(as_model)] << model.name
            end
            destination_table, rel_type =
                if reflection_object.macro == :has_and_belongs_to_many
                  join_table = to_name(reflection_object.join_table)
                  models_data[:tables][join_table] ||= {hidden_table: true}
                  models_data[:tables][join_table][reflection_object.foreign_key] = {}
                  [join_table, :has_many]
                else
                  [dest_model_name, reflection_object.macro]
                end
            self_ref_name = reflection_object.options[:class_name]
            if self_ref_name.present? && self_ref_name == model.name
              reflections_data[destination_table] ||=[]
              reflections_data[destination_table] << {
                  key: get_key(reflection_name, model, reflection_object.macro),
                  rel_type: rel_type,
                  alias: reflection_object.options[:class_name].present? ? reflection_name : nil,
                  options: reflection_object.options
              }
            else
              reflections_data[destination_table] = {
                  key: get_key(reflection_name, model, reflection_object.macro),
                  rel_type: rel_type,
                  alias: reflection_object.options[:class_name].present? ? reflection_name : nil,
                  options: reflection_object.options
              }
            end
          end
        end
      end

    end

    def get_key(r_name, model, rel_type)
      if rel_type == :belongs_to
        model.primary_key
      else
        model.reflect_on_association(r_name.to_sym).foreign_key
      end
    end

    def convert_default(default)
      default.to_s if default
    end

    def to_name(name, singular = false)
      name = name.to_s.camelize
      name = name.singularize if singular
      name
    end
  end
end
