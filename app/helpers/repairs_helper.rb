module RepairsHelper
  # Says what the photo shows: the bike, by name and serial number, and the
  # repair. With a position it also says which of the repair's photos it is.
  def intake_photo_alt(repair, position: nil, count: nil)
    photo = position ? "Intake photo #{position} of #{count}" : "Intake photo"
    bike = repair.bike
    "#{photo} of the #{bike.make} #{bike.model} (#{bike.serial_number}), repair ##{repair.id}"
  end

  # The start of the diagnosis as plain text, on one line, for lists.
  def diagnosis_excerpt(repair, length: 50)
    text = repair.diagnosis.to_plain_text.squish
    text.present? ? truncate(text, length: length) : "—"
  end
end
