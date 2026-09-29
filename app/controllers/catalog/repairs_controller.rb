class Catalog::RepairsController < ApplicationController
  def index
    @repairs = Repair.includes(:mechanic, bike: :customer).by_promised_on
  end

  def show
    @repair = Repair.includes(:mechanic, bike: :customer).find(params[:id])
    @repair_line_items = @repair.repair_line_items.includes(:service).oldest_first
    @payments = @repair.payments.oldest_first
  end
end
