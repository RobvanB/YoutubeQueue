class AddFileToYtqParams < ActiveRecord::Migration[5.2]
  def change
    add_column :ytq_params, :fileContents, :binary
  end
end
