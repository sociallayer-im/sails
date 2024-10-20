class Api::CommentController < ApiController
  def create
    profile = current_profile!

    comment = Comment.new(comment_params)
    if comment.update(
      profile: profile,
    )
      render json: { result: "ok", comment: comment.as_json }
    else
      render json: { result: "error", message: comment.errors.full_messages.join(", ") }
    end
  end

  def index
    profile = current_profile!

    comments = Comment.includes(:profile).where(comment_type: params[:comment_type], item_type: params[:item_type], item_id: params[:item_id], removed: nil).order(created_at: :desc)
    render json: { result: "ok", comments: comments.as_json(include: {profile: {only: [:id, :handle, :nickname, :image_url]}}) }
  end

  private

  def comment_params
    params.require(:comment).permit(:title, :item_type, :item_id, :reply_parent_id, :content, :content_type, :profile_id, :removed, :status, :comment_type, :icon_url, :edit_parent_id, :badge_id)
  end
end