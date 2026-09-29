class Catalog::BikesController < ApplicationController
  before_action :set_bike, only: %i[show edit update destroy]

  def index
    @bikes = Bike.includes(:customer).by_make_and_model
  end

  def show
    @repairs = @bike.repairs.newest_first
  end

  # From a customer's page the owner comes already chosen.
  def new
    @bike = Bike.new(customer: Customer.find_by(id: params[:customer_id]))
  end

  def create
    @bike = Bike.new(bike_params)
    if @bike.save
      redirect_to catalog_bike_path(@bike), notice: "Bike #{@bike.serial_number} was added."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @bike.update(bike_params)
      redirect_to catalog_bike_path(@bike), notice: "Bike #{@bike.serial_number} was updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @bike.destroy
      redirect_to catalog_bikes_path, notice: "Bike #{@bike.serial_number} was deleted.", status: :see_other
    else
      redirect_to catalog_bike_path(@bike), alert: @bike.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def set_bike
    @bike = Bike.find(params[:id])
  end

  def bike_params
    params.expect(bike: [ :customer_id, :make, :model, :color, :serial_number ])
  end
end
