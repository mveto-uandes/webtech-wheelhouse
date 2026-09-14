class Catalog::EmployeesController < ApplicationController
  def index
    @employees = Employee.order(:name)
  end

  def show
    @employee = Employee.find(params[:id])
  end
end
