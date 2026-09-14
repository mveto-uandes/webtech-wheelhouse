class Catalog::BikesController < ApplicationController
  def index
    @bikes = Bike.includes(:customer).order(:make, :model)
  end

  def show
    @bike = Bike.includes(:repairs).find(params[:id])
  end
end
