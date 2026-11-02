class Catalog::PaymentsController < ApplicationController
  def index
    authorize Payment
    @payments = policy_scope(Payment).includes(:repair).newest_first
  end

  def show
    @payment = authorize Payment.includes(:repair).find(params[:id])
  end
end
