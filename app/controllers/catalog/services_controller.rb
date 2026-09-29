class Catalog::ServicesController < ApplicationController
  def index
    @services = Service.by_name
  end

  def show
    @service = Service.find(params[:id])
    @repair_line_items = @service.repair_line_items.includes(:repair).newest_first
  end
end
