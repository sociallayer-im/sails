if @profile
  json.profile do
    json.partial! 'api/profile/profile_full', profile: @profile
  end
else
  json.profile nil
end