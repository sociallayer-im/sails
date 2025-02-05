class CommentMailer < ApplicationMailer
    default from: 'Social Layer <send@app.sola.day>'
    def feedback
      @comment_id = params[:comment_id]
      @comment = Comment.find(@comment_id)
      @recipient = @comment.item.owner.email
      @event = @comment.item
      mail(to: [@recipient], subject: 'Social Layer Feedback')
    end
  end
