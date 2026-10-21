# Repairs, for the shop's accounting program. Every route here needs the token.
class Api::V1::RepairsController < Api::V1::BaseController
  def index
    repairs = Repair.includes(bike: :customer, repair_line_items: :service).by_promised_on

    if params.key?(:state)
      unless Repair.statuses.key?(params[:state])
        raise ActionController::BadRequest, "State must be one of: #{Repair.statuses.keys.join(", ")}."
      end
      repairs = repairs.where(status: params[:state])
    end

    render json: repairs.map { |repair| repair_document(repair) }
  end

  def show
    repair = Repair.includes(bike: :customer, repair_line_items: :service).find(params[:id])
    render json: repair_document(repair)
  end

  private

  # What accounting needs to bill a repair. The phone, the mechanic, the
  # workshop's notes, the photos and every foreign key stay out (docs/api.md).
  def repair_document(repair)
    {
      id: repair.id,
      state: repair.status,
      received_on: repair.created_at.to_date,
      promised_on: repair.promised_on,
      handed_back_on: repair.handed_back_at&.to_date,
      customer_answer: repair.customer_answer,
      overdue: repair.overdue?,
      customer: { name: repair.bike.customer.name },
      bike: {
        make: repair.bike.make,
        model: repair.bike.model,
        serial_number: repair.bike.serial_number
      },
      lines: repair.repair_line_items.sort_by(&:id).map do |line|
        { service: line.service.name, charged_price: money(line.charged_price) }
      end,
      total: money(repair.total)
    }
  end
end
