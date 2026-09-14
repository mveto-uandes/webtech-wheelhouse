class Catalog::RepairLineItemsController < ApplicationController
  def index
    @repair_line_items = RepairLineItem.order(created_at: :desc)
  end

  def show
    @repair_line_item = RepairLineItem.find(params[:id])
  end
end
