class Catalog::RepairLineItemsController < ApplicationController
  def index
    @repair_line_items = RepairLineItem.includes(:repair, :service).newest_first
  end

  def show
    @repair_line_item = RepairLineItem.includes(:repair, :service).find(params[:id])
  end
end
