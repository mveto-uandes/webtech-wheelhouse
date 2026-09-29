class Catalog::PaymentsController < ApplicationController
  def index
    @payments = Payment.includes(:repair).newest_first
  end

  def show
    @payment = Payment.includes(:repair).find(params[:id])
  end
end
