module ApplicationHelper
  def field_class(object, field, base_class)
    object.errors[field].any? ? "#{base_class} is-invalid" : base_class
  end

  def invalid_feedback(object, field)
    return if object.errors[field].empty?

    content_tag(:div, object.errors[field].join(", "), class: "invalid-feedback")
  end

  def intake_photo_alt(repair_order)
    bike = repair_order.bike
    "Intake photo of #{bike.make} #{bike.model} for repair ##{repair_order.id}"
  end
end
