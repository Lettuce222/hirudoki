class Pagination
  PAGE_SIZE = 20

  attr_reader :records, :page, :total_count, :total_pages, :filters

  def initialize(scope, page:, filters: {})
    @total_count = scope.count
    @total_pages = [ (total_count + PAGE_SIZE - 1) / PAGE_SIZE, 1 ].max
    @page = (Integer(page.to_s, 10, exception: false) || 1).clamp(1, total_pages)
    @filters = filters
    @records = scope.offset(offset).limit(PAGE_SIZE)
  end

  def first_item
    total_count.zero? ? 0 : offset + 1
  end

  def last_item
    [ offset + PAGE_SIZE, total_count ].min
  end

  private

  def offset
    (page - 1) * PAGE_SIZE
  end
end
