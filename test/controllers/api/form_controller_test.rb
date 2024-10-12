require "test_helper"

class Api::FormControllerTest < ActionDispatch::IntegrationTest
  test "should submit form" do
    profile = Profile.find_by(handle: "cookie")
    auth_token = profile.gen_auth_token
    group = Group.find_by(handle: "guildx")
    custom_form = CustomForm.create(title: "test", group_id: group.id)
    form_field = FormField.create(label: "test", field_type: "text", custom_form_id: custom_form.id)
    post "/form/submit", params: { auth_token: auth_token, submission: { custom_form_id: custom_form.id, answers: { form_field.id.to_s => "test" } } }
    assert_response :success
  end
end
