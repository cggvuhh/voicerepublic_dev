class CreateVideoServers < ActiveRecord::Migration
  def change
    create_table :video_servers do |t|
      t.string :name
      t.string :url
      t.string :salt
      t.string :version
      t.boolean :activated

      t.timestamps
    end
  end
end
