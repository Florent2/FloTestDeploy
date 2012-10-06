class AddTitiToProducts < ActiveRecord::Migration
  def change
    add_column :products, :titi, :string
  end
end
