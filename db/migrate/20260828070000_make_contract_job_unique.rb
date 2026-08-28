class MakeContractJobUnique < ActiveRecord::Migration[8.1]
  def up
    remove_index :contracts, :job_id
    add_index :contracts, :job_id, unique: true
  end

  def down
    remove_index :contracts, :job_id
    add_index :contracts, :job_id
  end
end
