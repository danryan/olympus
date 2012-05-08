class CreateApps < ActiveRecord::Migration
  def change
    create_table :apps do |t|
      t.string :name
      t.string :runtime
      t.string :framework
      t.integer :instances, :default => 1
      t.string :state, :default => :stopped
      t.integer :memory, :default => 256
      
      t.text :env_vars
      
      t.timestamps
    end
  end
end
