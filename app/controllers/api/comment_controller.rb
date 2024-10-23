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

  def remove
    comment = Comment.find(params[:id])
    comment.update(removed: true)
    render json: { result: "ok" }
  end

  def list
    comments = Comment.includes(:profile).where(comment_type: params[:comment_type], removed: nil)
    comments = comments.where(item_type: params[:item_type]) if params[:item_type]
    comments = comments.where(item_id: params[:item_id]) if params[:item_id]
    comments = comments.where(profile_id: params[:profile_id]) if params[:profile_id]
    comments = comments.order(created_at: :desc)
    render json: { result: "ok", comments: comments.as_json(include: {profile: {only: [:id, :handle, :nickname, :image_url]}}) }
  end

  private

  def comment_params
    params.require(:comment).permit(:title, :item_type, :item_id, :reply_parent_id, :content, :content_type, :profile_id, :removed, :status, :comment_type, :icon_url, :edit_parent_id, :badge_id)
  end
end
