class AddIndexToVideos < ActiveRecord::Migration[5.2]
  def change
  	change_table :videos do |t|
  		t.index [:channel, :title], unique: true
	end
  end
end
