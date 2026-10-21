# The wall price list. Reading it is public; adding a service needs the token.
class Api::V1::ServicesController < Api::V1::BaseController
  skip_before_action :authenticate!, only: %i[index show]

  def index
    services = with_repairs_count(Service.by_name)
    render json: services.map { |service| service_document(service, service.repairs_count) }
  end

  def show
    service = with_repairs_count(Service).find(params[:id])
    render json: service_document(service, service.repairs_count)
  end

  def create
    service = Service.new(service_params)
    if service.save
      render json: service_document(service, 0), status: :created, location: api_v1_service_url(service)
    else
      render_errors service.errors.full_messages, :unprocessable_content
    end
  end

  private

  def service_params
    params.expect(service: [ :name, :price ])
  end

  # How many repairs charged each service, counted by the database in the same
  # query as the services. A repair that charged a service twice counts once.
  def with_repairs_count(services)
    services
      .left_joins(:repair_line_items)
      .group(:id)
      .select("services.*, COUNT(DISTINCT repair_line_items.repair_id) AS repairs_count")
  end

  def service_document(service, repairs_count)
    {
      id: service.id,
      name: service.name,
      price: money(service.price),
      repairs_count: repairs_count
    }
  end
end
