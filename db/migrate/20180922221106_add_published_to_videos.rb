class AddPublishedToVideos < ActiveRecord::Migration[5.2]
  def change
    add_column :videos, :published, :date
  end
end
