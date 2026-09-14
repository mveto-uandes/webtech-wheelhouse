class Catalog::RepairsController < ApplicationController
  def index
    @repairs = Repair.order(promised_on: :asc)
  end

  def show
    @repair = Repair.find(params[:id])
  end
end
