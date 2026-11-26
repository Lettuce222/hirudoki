module UiHelper
  def pagination_path(pagination, page)
    url_for(pagination.filters.merge(page:, only_path: true))
  end

  def primary_action_link(label, path)
    link_to label, path, class: "btn btn-primary"
  end
end
