class Catalog::BikesController < ApplicationController
  before_action :set_bike, only: %i[show edit update destroy]

  def index
    authorize Bike
    @bikes = policy_scope(Bike).includes(:customer).by_make_and_model
  end

  def show
    @repairs = policy_scope(@bike.repairs).includes(:mechanic, { taken_in_by: :employee }, bike: :customer)
      .with_attached_intake_photos.with_rich_text_diagnosis_and_embeds.newest_first
  end

  # From a customer's page the owner comes already chosen.
  def new
    @bike = authorize Bike.new(customer: policy_scope(Customer).find_by(id: params[:customer_id]))
  end

  def create
    @bike = authorize Bike.new(bike_params)
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
    @bike = authorize Bike.find(params[:id])
  end

  def bike_params
    params.expect(bike: [ :customer_id, :make, :model, :color, :serial_number ])
  end
end
