module CustomerUiHelper
  def customer_primary_link(label, path)
    link_to label, path, class: "btn btn-primary"
  end
end
