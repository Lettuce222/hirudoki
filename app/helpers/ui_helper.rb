module UiHelper
  def primary_action_link(label, path)
    link_to label, path, class: "btn btn-primary"
  end
end
