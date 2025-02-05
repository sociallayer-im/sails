module Core
  class Api < Grape::API
    version 'v1', using: :header, vendor: 'sola'
    format :json

    get :hello do
      { hello: 'world' }
    end
  end
end
