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

  # The field's own messages, shown right under it. Nothing when it's valid.
  def field_errors(object, attribute)
    return unless object.errors.include?(attribute)

    tag.div(object.errors.full_messages_for(attribute).to_sentence, class: "invalid-feedback")
  end
end
