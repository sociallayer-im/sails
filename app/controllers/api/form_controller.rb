class Api::FormController < ApiController

  def submit
    @submission = Submission.new(submission_params)
    @submission.profile_id = current_profile.id
    if @submission.save
      render template: "api/form/show"
    else
      render json: { error: @submission.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def submission_params
    params.require(:submission).permit(:custom_form_id, :answers)
  end
end
