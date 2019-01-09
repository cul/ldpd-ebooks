class FeedsController < ApplicationController

  def index
    # just redirecting for now. will have a more useful index later.
    redirect_to action: 'ia'
    return
  end

  def ia
    @page = params.fetch(:page, 1).to_i
    @per_page = 20
  end
end
