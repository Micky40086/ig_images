class CreateIgItem < ActiveRecord::Migration[5.2]
  def change
    create_table :ig_items do |t|
      t.references :user, foreign_key: true
      t.string :account
    end
  end
end
