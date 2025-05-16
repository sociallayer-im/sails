class AddPerformanceIndexes < ActiveRecord::Migration[7.2]
  def change
    # Events indexes
    add_index :events, [:group_id, :status, :start_time]  # For listing upcoming/past events
    add_index :events, :owner_id               # For finding events by owner
    add_index :events, [:track_id, :status]    # For track-based event filtering
    add_index :events, :venue_id               # For venue event lookups
    add_index :events, :recurring_id           # For recurring event lookups

    # Participants indexes
    add_index :participants, [:profile_id, :status] # For finding user's events
    add_index :participants, [:event_id, :status]   # For event participant lists

    # Groups indexes
    add_index :groups, :handle                 # For finding groups by handle
    add_index :groups, :status                 # For active/frozen groups
    add_index :groups, :group_tags, using: :gin # For group tag filtering

    # Memberships indexes
    add_index :memberships, [:target_id, :role] # For finding group members by role

    # Activities indexes
    add_index :activities, [:item_type, :item_id] # For finding activities for items
    add_index :activities, :initiator_id          # For user activity history
    add_index :activities, :created_at            # For activity feeds

    # Tickets indexes
    add_index :tickets, [:event_id, :status]      # For event ticket listings
    add_index :tickets, [:group_id, :status]      # For group ticket listings

    # Ticket items indexes
    add_index :ticket_items, [:profile_id, :status] # For user ticket history
    add_index :ticket_items, [:event_id, :status]   # For event ticket sales
    add_index :ticket_items, :order_number          # For ticket lookups

    # Venues indexes
    add_index :venues, [:group_id, :visibility]    # For group venue listings

    # Comments indexes
    add_index :comments, [:item_type, :item_id, :status] # For item comments
    add_index :comments, [:profile_id, :comment_type]    # For user interactions

    # Markers indexes
    add_index :markers, [:group_id, :status]      # For group marker listings
    add_index :markers, [:geo_lat, :geo_lng]      # For location-based queries

  end
end
