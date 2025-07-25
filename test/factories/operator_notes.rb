FactoryBot.define do
  factory :operator_note do
    author_id { 1 }
    event_id { 1 }
    content { "MyText" }
    mentions { 1 }
  end
end
