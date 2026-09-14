class Catalog::EmployeesController < ApplicationController
  def index
    @employees = Employee.includes(:repairs).order(:name)
  end

  def show
    @employee = Employee.includes(repairs: :bike).find(params[:id])
  end
end
