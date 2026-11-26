class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :order, null: false, foreign_key: true, index: { unique: true }
      t.integer :rating, null: false, comment: "利用者が受取済み注文に付けた1から5の評価"
      t.text :comment
      t.timestamps

      t.check_constraint "rating BETWEEN 1 AND 5", name: "reviews_rating_range"
    end
  end
end
