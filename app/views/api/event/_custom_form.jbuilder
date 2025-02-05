if custom_form.present?
    json.custom_form do
      json.extract! custom_form, :id, :title, :description, :status
      json.form_fields custom_form.form_fields do |form_field|
        json.extract! form_field, :id, :label, :description, :field_type, :field_options, :required, :position
      end
    end
else
    json.custom_form nil
end
