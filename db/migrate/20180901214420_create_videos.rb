class CreateVideos < ActiveRecord::Migration[5.2]
  def change
    create_table :videos do |t|
      t.string :title
      t.string :url
      t.string :subscription
      t.string :channel
      t.boolean :watched

      t.timestamps
    end
  end
end
