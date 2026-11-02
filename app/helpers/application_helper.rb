module ApplicationHelper
  FLASH_CLASSES = { "notice" => "alert-success", "alert" => "alert-danger" }.freeze

  def flash_class(type)
    FLASH_CLASSES.fetch(type.to_s, "alert-info")
  end

  # Bootstrap class for a field, plus is-invalid when the attribute has errors.
  # `attribute` is the one errors are stored under (:customer for customer_id).
  def field_class(object, attribute, base = "form-control")
    object.errors.include?(attribute) ? "#{base} is-invalid" : base
  end

  # Whether this person's policy lets them write the attribute on the record's
  # form. Fields they can't write aren't drawn at all.
  def writes?(record, attribute)
    policy(record).permitted_attributes.any? do |permitted|
      permitted == attribute || (permitted.is_a?(Hash) && permitted.key?(attribute))
    end
  end

  # A record's name, linked to its page only for someone who may open it.
  def link_if_allowed(text, record, path)
    policy(record).show? ? link_to(text, path) : text
  end

  # Who took a repair in: the staff member's name (linked), the account's
  # address when it belongs to nobody on the staff, or a dash for old repairs.
  def taken_in_by(repair)
    user = repair.taken_in_by
    return tag.span("—", class: "text-body-secondary") unless user
    return user.email_address unless user.employee

    link_to user.employee.name, catalog_employee_path(user.employee)
  end

  # The field's own messages, shown right under it. Nothing when it's valid.
  def field_errors(object, attribute)
    return unless object.errors.include?(attribute)

    tag.div(object.errors.full_messages_for(attribute).to_sentence, class: "invalid-feedback")
  end
end
