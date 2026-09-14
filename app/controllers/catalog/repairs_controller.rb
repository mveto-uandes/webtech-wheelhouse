class Catalog::RepairsController < ApplicationController
  def index
    @repairs = Repair.includes(:bike, :mechanic, :repair_line_items, :payments).order(promised_on: :asc)
  end

  def show
    @repair = Repair.includes(:bike, :mechanic, { repair_line_items: :service }, :payments).find(params[:id])
  end
end
