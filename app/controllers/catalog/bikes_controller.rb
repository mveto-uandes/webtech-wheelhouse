class Catalog::BikesController < ApplicationController
  def index
    @bikes = Bike.includes(:customer).by_make_and_model
  end

  def show
    @bike = Bike.includes(:customer).find(params[:id])
    @repairs = @bike.repairs.newest_first
  end
end
