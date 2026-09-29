class Catalog::ServicesController < ApplicationController
  before_action :set_service, only: %i[show edit update destroy]

  def index
    @services = Service.by_name
  end

  def show
    @repair_line_items = @service.repair_line_items.includes(:repair).newest_first
  end

  def new
    @service = Service.new
  end

  def create
    @service = Service.new(service_params)
    if @service.save
      redirect_to catalog_service_path(@service), notice: "Service #{@service.name} was added to the price list."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @service.update(service_params)
      redirect_to catalog_service_path(@service), notice: "Service #{@service.name} was updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @service.destroy
      redirect_to catalog_services_path, notice: "Service #{@service.name} was removed from the price list.", status: :see_other
    else
      redirect_to catalog_service_path(@service), alert: @service.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def set_service
    @service = Service.find(params[:id])
  end

  def service_params
    params.expect(service: [ :name, :price ])
  end
end
