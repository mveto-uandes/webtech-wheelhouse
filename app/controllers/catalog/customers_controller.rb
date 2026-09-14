class Catalog::CustomersController < ApplicationController
  def index
    @customers = Customer.includes(:bikes).order(:name)
  end

  def show
    @customer = Customer.includes(:bikes).find(params[:id])
  end
end
