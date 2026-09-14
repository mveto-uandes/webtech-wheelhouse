class Catalog::PaymentsController < ApplicationController
  def index
    @payments = Payment.includes(:repair).order(paid_at: :desc)
  end

  def show
    @payment = Payment.find(params[:id])
  end
end
