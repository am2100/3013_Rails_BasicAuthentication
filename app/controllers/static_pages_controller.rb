class StaticPagesController < ApplicationController
  before_filter :authorize, only: :admin
  def home
  end

  def admin
  end
end
