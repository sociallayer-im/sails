module Components::ColumnPlantTextHelper
    def render_column_plant_text(id:nil, field:nil, value:nil, **options)
      options[:class] = "column-plant-text h-full w-[200px] text-nowrap overflow-hidden overflow-ellipsis #{options[:class]} "
      options[:class] = tw(options[:class])
  
      options.reverse_merge!(
        required: (options[:required] || false),
        disabled: (options[:disabled] || false),
        readonly: (options[:readonly] || false),
      )
      render partial: "dashboard/components/column_plant_text", locals: {text: value, value: value, field: field, id: id, options: options}
    end
  end
  