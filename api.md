# Sails API Documentation

## Authentication

Most endpoints require authentication via one of these methods:
- JWT token in Authorization header: `Authorization: Bearer <token>`
- `auth_token` query parameter
- Doorkeeper OAuth2 token

### Authentication Endpoints

#### Sign In Methods

```http
POST /siwe/verify
```
Verify Sign-In with Ethereum.
- Body: `{ signature: string, message: string }`
- Returns: `{ auth_token: string, address: string, id: number }`

```http
POST /profile/signin_with_email
```
Sign in with email verification code.
- Body: `{ email: string, code: string }`
- Returns: `{ auth_token: string, email: string, id: number }`

```http
POST /profile/signin_with_google
```
Sign in with Google OAuth.
- Body: `{ email: string, next_token: string }`
- Returns: `{ auth_token: string, email: string, id: number }`

Additional sign-in methods available for:
- ZK Email (`/profile/signin_with_zkemail`)
- Multi Zupass (`/profile/signin_with_multi_zupass`) 
- Solana (`/profile/signin_with_solana`)
- Farcaster (`/profile/signin_with_farcaster`)
- World ID (`/profile/signin_with_world_id`)
- Mina (`/profile/signin_with_mina`)
- Fuel (`/profile/signin_with_fuel`)
- Telegram (`/profile/signin_with_telegram`)

## Profile Management

```http
GET /profile/me
```
Get current authenticated user's profile.

```http
POST /profile/create
```
Create new profile.
- Body: `{ handle: string }`
- Requires: Valid handle format, unique handle
- Returns: `{ result: "ok" }`

```http
POST /profile/update 
```
Update profile details.
- Body: `{ image_url?: string, nickname?: string, about?: string, location?: string, social_links?: object }`
- Returns: `{ result: "ok" }`

```http
GET /profile/get_by_handle
```
Get profile by handle.
- Query: `?handle=<handle>`
- Returns: Profile entity

## Groups

### Group Management

```http
POST /group/create
```
Create new group.
- Body: `{ handle: string, ... }`
- Returns: `{ result: "ok", group: Group }`

```http
POST /group/update
```
Update group details.
- Body: Group parameters
- Requires: Manager permissions
- Returns: `{ result: "ok", group: Group }`

### Group Membership

```http
POST /group/add_manager
```
Add manager to group.
- Body: `{ group_id: number, profile_id: number }`
- Requires: Owner/manager permissions
- Returns: `{ result: "ok" }`

```http
POST /group/remove_manager
```
Remove manager from group.
- Body: `{ group_id: number, profile_id: number }`
- Requires: Owner permissions
- Returns: `{ result: "ok" }`

Similar endpoints exist for operators and members:
- `add_operator`, `remove_operator`
- `remove_member`
- `leave` (for self)

### Group Invites

```http
POST /group/send_invite
```
Send group invitation.
- Body: `{ group_id: number, receiver_id: number, role?: string }`
- Returns: `{ result: "ok" }`

```http
POST /group/accept_invite
```
Accept group invitation.
- Body: `{ invite_id: number }`
- Returns: `{ result: "ok" }`

## Activities

```http
POST /activity/set_read_status
```
Mark activities as read.
- Body: `{ ids: number[] }`
- Requires: Authentication, activities must belong to current user
- Returns: `{ result: "ok" }`

## Events

### Event Management

```http
POST /event/create
```
Create new event.
- Body: Event parameters including:
  - `title: string`
  - `start_time: datetime`
  - `end_time: datetime`
  - `group_id?: number`
  - `venue_id?: number`
  - Additional optional fields
- Returns: `{ result: "ok", event: Event }`

```http
POST /event/update
```
Update event details.
- Body: Event parameters
- Requires: Event owner or group manager permissions
- Returns: `{ result: "ok", event: Event }`

```http
POST /event/unpublish
```
Cancel/unpublish event.
- Body: `{ id: number }`
- Returns: `{ result: "ok", event: Event }`

### Event Participation

```http
POST /event/join
```
Join an event.
- Body: `{ id: number }`
- Returns: `{ participant: Participant }`

```http
POST /event/cancel
```
Cancel participation in event.
- Body: `{ id: number }`
- Returns: `{ participant: Participant }`

### Event Queries

```http
GET /event/list
```
List events for a group.
- Query parameters:
  - `group_id: number`
  - `collection?: "upcoming" | "past" | "pinned"`
  - `track_id?: number`
  - `tags?: string`
  - `search_title?: string`
  - `start_date?: date`
  - `end_date?: date`
  - Pagination: `page`, `limit`
- Returns: Array of events

```http
GET /event/discover
```
Get featured events and groups.
- Returns: 
  - `events`: Featured events
  - `featured_popups`: Featured popup events
  - `popups`: All popup events
  - `groups`: Top groups

## Venues

```http
POST /venue/create
```
Create venue.
- Body: Venue parameters
- Returns: `{ venue: Venue }`

```http
POST /venue/check_availability
```
Check venue availability.
- Body: `{ id: number, start_time: datetime, end_time: datetime }`
- Returns: `{ available: boolean, message?: string }`

## Tickets

```http
POST /ticket/rsvp
```
RSVP for event with ticket.
- Body: 
  - `id: number` (event id)
  - `ticket_id: number`
  - `payment_method_id?: number`
- Returns: `{ participant: Participant, ticket_item: TicketItem }`

```http
POST /ticket/set_payment_status
```
Update ticket payment status.
- Body: Payment details
- Returns: `{ participant: Participant, ticket_item: TicketItem }`

## Comments

```http
POST /comment/create
```
Create a comment.
- Body:
  - `title?: string`
  - `item_type: string`
  - `item_id: number`
  - `content: string`
  - `content_type?: string`
  - `comment_type?: string`
  - `reply_parent_id?: number`
  - `icon_url?: string`
- Returns: `{ result: "ok", comment: Comment }`

```http
POST /comment/remove
```
Remove a comment.
- Body: `{ id: number }`
- Returns: `{ result: "ok" }`

```http
POST /comment/star
```
Star an item.
- Body: `{ item_type: string, item_id: number }`
- Returns: `{ result: "ok" }`

```http
POST /comment/unstar
```
Remove star from an item.
- Body: `{ item_type: string, item_id: number }`
- Returns: `{ result: "ok" }`

```http
GET /comment/list
```
List comments.
- Query Parameters:
  - `comment_type?: string`
  - `item_type?: string`
  - `item_id?: number`
  - `profile_id?: number`
- Returns: `{ result: "ok", comments: Comment[] }`

## Group Invites

```http
POST /group/request_invite
```
Request to join a group.
- Body:
  - `group_id: number`
  - `role?: string`
  - `message?: string`
- Returns: `{ group_invite: GroupInvite }`

```http
POST /group/accept_request
```
Accept a group join request.
- Body: `{ group_invite_id: number }`
- Requires: Group manager permissions
- Returns: `{ result: "ok", membership: Membership }`

```http
POST /group/send_invite
```
Send group invitations.
- Body:
  - `group_id: number`
  - `receivers: string[]` (handles, addresses, or emails)
  - `role: string`
  - `message?: string`
- Requires: Group manager permissions
- Returns: `{ group_invites: GroupInvite[] }`

```http
POST /group/accept_invite
```
Accept a group invitation.
- Body: `{ group_invite_id: number }`
- Returns: `{ result: "ok" }`

```http
POST /group/cancel_invite
```
Cancel a group invitation (as receiver).
- Body: `{ group_invite_id: number }`
- Returns: `{ result: "ok" }`

```http
POST /group/revoke_invite
```
Revoke a group invitation (as sender).
- Body: `{ group_invite_id: number }`
- Requires: Group manager permissions
- Returns: `{ result: "ok" }`

## Markers

```http
POST /marker/create
```
Create a location marker.
- Body:
  - `group_id: number`
  - `marker_type: "site" | "event" | "share"`
  - `category?: string`
  - `pin_image_url?: string`
  - `cover_image_url?: string`
  - `title: string`
  - `about?: string`
  - `link?: string`
  - `location?: string`
  - `formatted_address?: string`
  - `location_viewport?: object`
  - `location_data?: object`
  - `geo_lat?: number`
  - `geo_lng?: number`
  - `start_time?: datetime`
  - `end_time?: datetime`
- Returns: `{ marker: Marker }`

```http
POST /marker/update
```
Update a marker.
- Body: Same as create
- Requires: Marker owner or group manager permissions
- Returns: `{ marker: Marker }`

```http
POST /marker/remove
```
Remove a marker.
- Body: `{ id: number }`
- Requires: Marker owner or group manager permissions
- Returns: `{ result: "ok" }`

```http
POST /marker/checkin
```
Check in at a marker location.
- Body:
  - `id: number`
  - `title?: string`
  - `content?: string`
  - `content_type?: string`
  - `reply_parent_id?: number`
  - `icon_url?: string`
- Returns: `{ result: "ok", comment: Comment }`

```http
GET /marker/list
```
List markers for a group.
- Query Parameters:
  - `group_id: number`
  - `marker_type?: string`
  - `category?: string`
- Returns: Array of markers

```http
GET /marker/get
```
Get a single marker.
- Query Parameters: `id: number`
- Returns: Marker object

## Recurring Events

```http
POST /recurring/create
```
Create recurring events.
- Body:
  - `group_id?: number`
  - `start_time: datetime`
  - `end_time: datetime`
  - `interval: "day" | "week" | "month"`
  - `event_count: number`
  - `timezone: string`
  - `venue_id?: number`
  - Event parameters (same as event/create)
- Returns: `{ result: "ok", recurring: Recurring }`

```http
POST /recurring/update
```
Update recurring events.
- Body:
  - `recurring_id: number`
  - `selector?: "after"`
  - `after_event_id?: number`
  - `start_time_diff?: number` (seconds)
  - `end_time_diff?: number` (seconds)
  - Event parameters
- Returns: `{ result: "ok" }`

```http
POST /recurring/cancel_event
```
Cancel recurring events.
- Body:
  - `recurring_id: number`
  - `selector?: "after"`
  - `event_id?: number`
- Returns: `{ result: "ok" }`

## Voting System

```http
POST /vote/create
```
Create a vote proposal.
- Body:
  - `group_id: number`
  - `title: string`
  - `content: string`
  - `show_voters?: boolean`
  - `max_choice?: number`
  - `eligibile_group_id?: number`
  - `eligibile_badge_class_id?: number`
  - `eligibile_point_id?: number`
  - `verification?: string`
  - `eligibility?: string`
  - `can_update_vote?: boolean`
  - `start_time?: datetime`
  - `end_time?: datetime`
  - `vote_options_attributes: VoteOption[]`
- Requires: Group create_vote permission
- Returns: `{ proposal: VoteProposal }`

```http
POST /vote/update
```
Update a vote proposal.
- Body: Same as create
- Requires: Proposal update permission
- Returns: `{ proposal: VoteProposal }`

```http
POST /vote/cancel
```
Cancel a vote proposal.
- Body: `{ id: number }`
- Requires: Proposal cancel permission
- Returns: `{ result: "ok" }`

```http
POST /vote/cast_vote
```
Cast vote for a proposal.
- Body:
  - `id: number` (proposal id)
  - `option: number[]` (option ids)
- Validation:
  - Must not exceed proposal's max_choice
  - User must not have voted before
  - Must be within voting time window
  - Must meet eligibility requirements
- Returns: `{ result: "ok", voter_records: VoteRecord }`

## Voucher System

```http
POST /voucher/create
```
Create a voucher.
- Body:
  - `badge_class_id: number`
  - `badge_title?: string`
  - `badge_content?: string`
  - `badge_image?: string`
  - `message?: string`
  - `counter?: number` (default: 65535)
  - `expires_at?: datetime`
  - `value?: number`
  - `start_time?: datetime`
  - `end_time?: datetime`
- Returns: `{ voucher: Voucher }`

```http
POST /voucher/use
```
Use/claim a voucher.
- Body:
  - `id: number`
  - `code?: string` (required for code strategy)
- Returns: `{ badge: Badge }`

```http
POST /voucher/revoke
```
Revoke a voucher.
- Body: `{ id: number }`
- Requires: Voucher update permission
- Returns: `{ voucher: Voucher, badge_class: BadgeClass }`

```http
GET /voucher/get_code
```
Get voucher code.
- Query: `id: number`
- Requires: Voucher read permission
- Returns: `{ voucher_id: number, code: string }`

```http
POST /voucher/send_badge
```
Send badge vouchers to users.
- Body:
  - `badge_class_id: number`
  - `receivers: string[]` (handles/addresses/emails)
  - `badge_title?: string`
  - `badge_content?: string`
  - `badge_image?: string`
  - `message?: string`
  - `expires_at?: datetime`
  - `value?: number`
  - `start_time?: datetime`
  - `end_time?: datetime`
- Returns: `{ vouchers: Voucher[] }`

```http
POST /voucher/send_badge_by_address
```
Send badge vouchers by blockchain addresses.
- Body: Same as send_badge
- Returns: `{ vouchers: Voucher[] }`

```http
POST /voucher/send_badge_by_email
```
Send badge vouchers by email addresses.
- Body: Same as send_badge
- Returns: `{ vouchers: Voucher[] }`

```http
POST /voucher/reject_badge
```
Reject a badge voucher.
- Body: `{ id: number }`
- Returns: `{ voucher: Voucher, badge_class: BadgeClass }`

### Additional Entity Types

### VoteProposal Entity
```typescript
{
  id: number
  title: string
  content: string
  group_id: number
  creator_id: number
  eligibility: string
  eligibile_group_id?: number
  eligibile_badge_class_id?: number
  eligibile_point_id?: number
  verification?: string
  status: string
  show_voters: boolean
  can_update_vote: boolean
  voter_count: number
  weight_count: number
  max_choice: number
  start_time?: string
  end_time?: string
  created_at: string
  vote_options: VoteOption[]
}
```

### VoteOption Entity
```typescript
{
  id: number
  group_id: number
  vote_proposal_id: number
  title: string
  link?: string
  content?: string
  image_url?: string
  voted_weight: number
  created_at: string
}
```

### Recurring Entity
```typescript
{
  id: number
  start_time: string
  end_time: string
  interval: string
  event_count: number
  timezone: string
}
```

### Voucher Entity
```typescript
{
  id: number
  sender_id: number
  badge_class_id: number
  badge_title?: string
  badge_content?: string
  badge_image?: string
  message?: string
  code?: string
  expires_at: string
  counter: number
  receiver_id?: number
  receiver_address?: string
  receiver_address_type?: string
  strategy: string
  data?: object
  created_at: string
}
```

## Badges

```http
POST /badge/transfer
```
Transfer badge to another user.
- Body: `{ badge_id: number, target: string }`
- Returns: `{ result: "ok" }`

```http
GET /badge/list
```
List badges.
- Query: `profile_id`, filters
- Returns: Array of badges

## Point Classes

```http
POST /point_class/create
```
Create a new point class.
- Body:
  - `name: string`
  - `title: string`
  - `sym?: string` (default: "pt")
  - `metadata?: object`
  - `content?: string`
  - `image_url?: string`
  - `transferable?: boolean`
  - `revocable?: boolean`
  - `group_id?: number`
- Requires: Group manager permission if group_id is provided
- Returns: `{ result: "ok", point_class: PointClass }`

## Remember System

```http
GET /remember/meta
```
Get remember badge types information.
- Returns: Array of remember types with badge class info

```http
POST /remember/create
```
Create a remember voucher.
- Body:
  - `badge_class_id: number`
  - `message?: string`
  - `expires_at?: datetime`
  - `value?: number`
  - `start_time?: datetime`
  - `end_time?: datetime`
- Returns: `{ voucher: Voucher, badge_class: BadgeClass, profile: Profile }`

```http
POST /remember/join
```
Join a remember voucher.
- Body: `{ voucher_id: number }`
- Returns: `{ activity: Activity, voucher: Voucher, badge_class: BadgeClass, sender: Profile }`

```http
POST /remember/cancel
```
Cancel participation in a remember voucher.
- Body: `{ voucher_id: number }`
- Returns: `{ result: "ok" }`

```http
GET /remember/get
```
Get remember voucher details.
- Query: `voucher_id: number`
- Returns: `{ activities: Activity[], voucher: Voucher, badge_class: BadgeClass }`

```http
POST /remember/mint
```
Mint badges for remember voucher participants.
- Body: `{ voucher_id: number }`
- Requires: At least 2 participants
- Returns: `{ voucher: Voucher, badge_class: BadgeClass, badges: Badge[] }`

## Service Endpoints

### Image Upload

```http
POST /service/upload_image
```
Upload image using ImageKit.
- Body: FormData with:
  - `data: File`
  - `resource: string`
- Returns: `{ result: ImageKitResponse }`

```http
POST /service/upload_image_v2
```
Upload image using Cloudflare Images.
- Body: FormData with `data: File`
- Returns: `{ result: CloudflareResponse }`

### Email Services

```http
POST /service/send_email
```
Send verification email.
- Body:
  - `email: string`
  - `context: string`
- Returns: `{ result: "ok", email: string }`

### Group Statistics

```http
GET /service/stats
```
Get group statistics.
- Query Parameters:
  - `group_id: number`
  - `days?: number` (filter by last N days)
- Returns:
  ```typescript
  {
    total_events: number
    total_event_hosts: number
    total_participants: number
  }
  ```

### Calendar Integration

```http
GET /service/icalendar_for_group
```
Get iCalendar feed for group events.
- Query: `group_id: number`
- Returns: iCalendar format text/calendar

### User Data Queries

```http
GET /service/get_participanted_events_by_email
```
Get events participated by email.
- Query Parameters:
  - `email: string`
  - `group_id?: number`
  - `collection?: "past" | "upcoming"`
- Returns: `{ events: Event[] }`

```http
GET /service/get_hosted_events_by_email
```
Get events hosted by email.
- Query Parameters:
  - `email: string`
  - `group_id?: number`
  - `collection?: "past" | "upcoming"`
- Returns: `{ events: Event[] }`

```http
GET /service/get_user_groups_by_email
```
Get groups joined by email.
- Query: `email: string`
- Returns: `{ groups: Group[] }`

```http
GET /service/get_user_tickets_by_email
```
Get tickets owned by email.
- Query: `email: string`
- Returns: `{ tickets: Ticket[] }`

### Additional Entity Types

### PointClass Entity
```typescript
{
  id: number
  name: string
  title: string
  sym: string
  metadata?: object
  content?: string
  image_url?: string
  creator_id: number
  group_id?: number
  transferable: boolean
  revocable: boolean
  point_type: "point" | "credit"
  total_supply: number
  created_at: string
}
```

### Activity Entity
```typescript
{
  id: number
  item_type?: string
  item_id?: number
  initiator_id: number
  action: string
  data?: string
  created_at: string
  has_read: boolean
  receiver_id?: number
  receiver_type?: string
  receiver_address?: string
}
```

## Web Session Management

```http
GET /sign_in
```
Show sign in page.

```http
POST /verify
```
Send email verification code.
- Body: 
  - `email: string`
  - `context: string`
- Returns: Redirects to verifier page

```http
GET /verifier
```
Show verification code input page.
- Query: `email: string`

```http
POST /sign_in
```
Sign in with email verification code.
- Body:
  - `email: string`
  - `code: string`
- Returns: Redirects to root with success message or error

```http
DELETE /sign_out
```
Sign out current session.
- Returns: Redirects to root with success message

```http
GET /sessions
```
List all profiles (admin only).
- Returns: List of profiles

```http
GET /sessions/:id
```
Show profile details.
- Returns: Profile details page

## Health Check

```http
GET /up
```
Application health check endpoint.
- Returns: "up" if application is running
- Status: 200 OK if healthy

## Demo Page

```http
GET /demo
```
Show demo page.

## Root Page

```http
GET /
```
Show application home page.

## Error Responses

Common error response format:
```json
{
  "result": "error",
  "message": "Error description"
}
```

Common HTTP status codes:
- 400: Bad Request
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 422: Unprocessable Entity
- 500: Internal Server Error
