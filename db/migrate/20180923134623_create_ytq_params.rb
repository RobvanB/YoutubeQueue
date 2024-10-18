class CreateYtqParams < ActiveRecord::Migration[5.2]
  def change
    create_table :ytq_params do |t|
      t.string :last_date

      t.timestamps
    end
  end
end
