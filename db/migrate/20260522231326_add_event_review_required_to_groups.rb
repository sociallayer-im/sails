class AddEventReviewRequiredToGroups < ActiveRecord::Migration[7.2]
  def change
    add_column :groups, :event_review_required, :boolean, default: false, null: false
  end
end
