class HomeController < ApplicationController
  def index
    # render json: "hello", layout: false
  end

  def demo
  end

  def up
    render json: "up"
  end
end
