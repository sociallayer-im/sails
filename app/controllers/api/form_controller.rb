class Api::FormController < ApiController

  def save_event_form
    profile = current_profile!
    event = Event.find(params[:event_id])
    authorize event, :update?

    form = event.form || Form.new(created_by_id: profile.id.to_s)
    form.title = params[:title] || "Application Form"
    form.published = true

    ActiveRecord::Base.transaction do
      form.save!
      event.update_column(:form_id, form.id) unless event.form_id == form.id

      FormField.where(form_id: form.id).delete_all
      (params[:fields] || []).each_with_index do |field_params, index|
        form.form_fields.create!(
          label: field_params[:label],
          field_type: field_params[:field_type] || 'text',
          required: field_params[:required] || false,
          for_admin: field_params[:for_admin] || false,
          position: field_params[:position].present? ? field_params[:position] : index
        )
      end
    end

    render json: { form: form_json(form.reload) }
  end

  def get_event_form
    event = Event.find(params[:event_id])
    form = event.form
    render json: { form: form ? form_json(form) : nil }
  end

  def list_submissions
    profile = current_profile!
    form = Form.find(params[:form_id])
    event = Event.find_by(form_id: form.id)
    raise AppError.new("not authorized") unless event && EventPolicy.new(profile, event).update?

    submissions = form.form_submissions.includes(:form_answers)
    render json: { submissions: submissions.map { |s| submission_json(s) } }
  end

  private

  def form_json(form)
    form.as_json(only: [:id, :title, :description, :published]).merge(
      fields: form.form_fields.map { |f|
        f.as_json(only: [:id, :label, :field_type, :required, :for_admin, :position])
      }
    )
  end

  def submission_json(submission)
    p = submission.profile
    submission.as_json(only: [:id, :form_id, :user_id, :status, :starred, :admin_note, :submitted_at]).merge(
      answers: submission.form_answers.map { |a| a.as_json(only: [:id, :form_field_id, :value]) },
      profile: p&.as_json(only: [:id, :handle, :nickname, :image_url])
    )
  end
end
