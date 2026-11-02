class Catalog::ServicesController < ApplicationController
  # Anyone can read the services; changing them needs a session.
  allow_unauthenticated_access only: %i[index show]
  before_action :set_service, only: %i[show edit update destroy]

  def index
    authorize Service
    @services = policy_scope(Service).by_name
  end

  def show
    # Only the lines of repairs this person may read.
    @repair_line_items = @service.repair_line_items.where(repair: policy_scope(Repair)).includes(:repair).newest_first
  end

  def new
    @service = authorize Service.new
  end

  def create
    @service = authorize Service.new(service_params)
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
    @service = authorize Service.find(params[:id])
  end

  def service_params
    params.expect(service: [ :name, :price ])
  end
end
