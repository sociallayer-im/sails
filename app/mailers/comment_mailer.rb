class CommentMailer < ApplicationMailer
    default from: 'Social Layer <send@app.sola.day>'
    def feedback
      @comment_id = params[:comment_id]
      @comment = Comment.find(@comment_id)
      event = Event.find(@comment.item_id)
      @recipient = event.creator.email
      mail(to: [@recipient], subject: 'Social Layer Feedback')
    end
  end
