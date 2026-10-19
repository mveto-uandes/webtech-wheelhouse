class Catalog::RepairsController < ApplicationController
  # Empty lines offered at the bottom of the repair's form. Without JavaScript
  # the form can't grow, so a repair that needs more lines is saved and edited
  # again, which offers this many more.
  BLANK_LINES = 3

  before_action :set_repair, only: %i[show edit update destroy]

  def index
    @repairs = Repair.includes(:mechanic, bike: :customer)
      .with_attached_intake_photos.with_rich_text_diagnosis_and_embeds.by_promised_on
  end

  def show
    @intake_photos = @repair.intake_photos_attachments
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
    @intake_photos = @repair.intake_photos_attachments
    add_blank_lines
  end

  # Photos chosen in the edit form join the ones on file. Assigning them would
  # replace the whole set, and leaving the field empty keeps it as it was.
  def update
    attributes = repair_params
    new_photos = Array(attributes.delete(:intake_photos)).compact_blank
    @repair.assign_attributes(attributes)
    @repair.intake_photos = @repair.intake_photos.blobs + new_photos if new_photos.any?

    if @repair.save
      redirect_to catalog_repair_path(@repair), notice: "Repair ##{@repair.id} for bike #{@repair.bike.serial_number} was updated."
    else
      @intake_photos = @repair.intake_photos_attachments
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
    @repair = Repair.with_attached_intake_photos.with_rich_text_diagnosis_and_embeds.find(params[:id])
  end

  def add_blank_lines
    BLANK_LINES.times { @repair.repair_line_items.build }
  end

  def repair_params
    params.expect(repair: [
      :bike_id, :mechanic_id, :status, :reported_problem, :diagnosis, :promised_on, :handed_back_at,
      intake_photos: [],
      repair_line_items_attributes: [ [ :id, :service_id, :charged_price, :_destroy ] ]
    ])
  end
end
