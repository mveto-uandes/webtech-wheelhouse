class Catalog::RepairsController < ApplicationController
  # Empty lines offered at the bottom of the repair's form. Without JavaScript
  # the form can't grow, so a repair that needs more lines is saved and edited
  # again, which offers this many more.
  BLANK_LINES = 3

  before_action :set_repair, only: %i[show edit update destroy]

  def index
    @repairs = Repair.includes(:mechanic, bike: :customer).by_promised_on
  end

  def show
    @repair_line_items = @repair.repair_line_items.includes(:service).oldest_first
    @payments = @repair.payments.oldest_first
  end

  # From a bike's page the bike comes already chosen.
  def new
    @repair = Repair.new(bike: Bike.find_by(id: params[:bike_id]))
    add_blank_lines
  end

  def create
    @repair = Repair.new(repair_params)
    if @repair.save
      redirect_to catalog_repair_path(@repair), notice: "Repair ##{@repair.id} for bike #{@repair.bike.serial_number} was taken in."
    else
      add_blank_lines
      render :new, status: :unprocessable_content
    end
  end

  def edit
    add_blank_lines
  end

  def update
    if @repair.update(repair_params)
      redirect_to catalog_repair_path(@repair), notice: "Repair ##{@repair.id} for bike #{@repair.bike.serial_number} was updated."
    else
      add_blank_lines
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @repair.destroy
      redirect_to catalog_repairs_path, notice: "Repair ##{@repair.id} for bike #{@repair.bike.serial_number} was deleted.", status: :see_other
    else
      redirect_to catalog_repair_path(@repair), alert: @repair.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def set_repair
    @repair = Repair.find(params[:id])
  end

  def add_blank_lines
    BLANK_LINES.times { @repair.repair_line_items.build }
  end

  def repair_params
    params.expect(repair: [
      :bike_id, :mechanic_id, :status, :reported_problem, :diagnosis, :promised_on, :handed_back_at,
      repair_line_items_attributes: [ [ :id, :service_id, :charged_price, :_destroy ] ]
    ])
  end
end
