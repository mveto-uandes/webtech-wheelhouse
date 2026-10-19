# Removes one intake photo from a repair, from its page or its edit page. The
# attachment, the blob and the stored file all go; the other photos stay.
class Catalog::IntakePhotosController < ApplicationController
  before_action :set_repair

  def destroy
    photo = @repair.intake_photos.find(params[:id])
    photo.purge
    redirect_back_or_to catalog_repair_path(@repair),
      notice: "The photo was removed from repair ##{@repair.id}.", status: :see_other
  end

  private

  def set_repair
    @repair = Repair.find(params[:repair_id])
  end
end
