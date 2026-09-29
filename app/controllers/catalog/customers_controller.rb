class Catalog::CustomersController < ApplicationController
  before_action :set_customer, only: %i[show edit update destroy]

  def index
    @customers = Customer.includes(:bikes).by_name
  end

  def show
    @bikes = @customer.bikes.by_make_and_model
  end

  def new
    @customer = Customer.new
  end

  def create
    @customer = Customer.new(customer_params)
    if @customer.save
      redirect_to catalog_customer_path(@customer), notice: "Customer #{@customer.name} was added."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @customer.update(customer_params)
      redirect_to catalog_customer_path(@customer), notice: "Customer #{@customer.name} was updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @customer.destroy
      redirect_to catalog_customers_path, notice: "Customer #{@customer.name} was deleted.", status: :see_other
    else
      redirect_to catalog_customer_path(@customer), alert: @customer.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    params.expect(customer: [ :name, :phone ])
  end
end
