class Catalog::ServicesController < ApplicationController
  def index
    @services = Service.order(:name)
  end

  def show
    @service = Service.includes(repair_line_items: :repair).find(params[:id])
  end
end
