class ChangeEventReviewRequiredToStringInGroups < ActiveRecord::Migration[7.2]
  def change
    remove_column :groups, :event_review_required, :boolean
    add_column :groups, :event_review_required, :string
  end
end
