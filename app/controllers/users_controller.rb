class UsersController < ApplicationController
  before_filter :authorize
  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      # If you want to automatically log the new user into the site:
      session[:user_id] = @user.id
      redirect_to root_url, notice: "Thank you for signing up!"
    else
      render "new"
    end
  end
end
