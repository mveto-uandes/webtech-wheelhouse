class Catalog::EmployeesController < ApplicationController
  def index
    @employees = Employee.includes(:repairs).by_name
  end

  def show
    @employee = Employee.find(params[:id])
    @repairs = @employee.repairs.includes(:bike).by_promised_on
  end
end
