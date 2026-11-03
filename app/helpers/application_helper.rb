module ApplicationHelper
  def field_class(object, field, base_class)
    object.errors[field].any? ? "#{base_class} is-invalid" : base_class
  end

  def invalid_feedback(object, field)
    return if object.errors[field].empty?

    content_tag(:div, object.errors[field].join(", "), class: "invalid-feedback")
  end

  # The form shows each person only the fields their policy lets them write.
  def permitted_field?(record, field)
    policy(record).permitted_attributes.any? do |attribute|
      attribute == field || (attribute.is_a?(Hash) && attribute.key?(field))
    end
  end

  def repair_filter_link(label, active, **filter)
    link_to label, repair_orders_path(**filter), class: "btn btn-sm #{active ? "btn-primary" : "btn-outline-primary"}"
  end

  def taken_in_by_label(repair_order)
    repair_order.taken_in_by&.display_name || "Not recorded"
  end

  def intake_photo_alt(repair_order)
    bike = repair_order.bike
    "Intake photo of #{bike.make} #{bike.model} for repair ##{repair_order.id}"
  end
end
