class Catalog::EmployeesController < ApplicationController
  before_action :set_employee, only: %i[show edit update destroy]

  def index
    @employees = Employee.includes(:repairs).by_name
  end

  def show
    @repairs = @employee.repairs.includes(:mechanic, bike: :customer)
      .with_attached_intake_photos.with_rich_text_diagnosis_and_embeds.by_promised_on
  end

  def new
    @employee = Employee.new
  end

  def create
    @employee = Employee.new(employee_params)
    if @employee.save
      redirect_to catalog_employee_path(@employee), notice: "#{@employee.name} was added to the staff."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @employee.update(employee_params)
      redirect_to catalog_employee_path(@employee), notice: "#{@employee.name} was updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @employee.destroy
      redirect_to catalog_employees_path, notice: "#{@employee.name} was removed from the staff.", status: :see_other
    else
      redirect_to catalog_employee_path(@employee), alert: @employee.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def set_employee
    @employee = Employee.find(params[:id])
  end

  def employee_params
    params.expect(employee: [ :name, :role ])
  end
end
