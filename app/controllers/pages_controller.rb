class PagesController < ApplicationController
  def home
    render plain: 'Ebooks!'
  end
end
