class CreateMarketplaceModels < ActiveRecord::Migration[8.1]
  def change
    create_table :client_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :company_name
      t.text :bio
      t.string :location
      t.boolean :payment_verified, null: false, default: false

      t.timestamps
    end

    create_table :freelancer_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :title
      t.text :bio
      t.integer :hourly_rate_cents
      t.string :location
      t.string :skills, array: true, null: false, default: []

      t.timestamps
    end

    create_table :jobs do |t|
      t.references :client, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description, null: false
      t.integer :budget_cents, null: false
      t.string :skills, array: true, null: false, default: []
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    create_table :proposals do |t|
      t.references :job, null: false, foreign_key: true
      t.references :freelancer, null: false, foreign_key: { to_table: :users }
      t.integer :amount_cents, null: false
      t.text :message, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end
    add_index :proposals, [ :job_id, :freelancer_id ], unique: true

    create_table :contracts do |t|
      t.references :job, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: { to_table: :users }
      t.references :freelancer, null: false, foreign_key: { to_table: :users }
      t.integer :amount_cents, null: false
      t.integer :status, null: false, default: 0
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    create_table :reviews do |t|
      t.references :contract, null: false, foreign_key: true
      t.references :reviewer, null: false, foreign_key: { to_table: :users }
      t.references :reviewee, null: false, foreign_key: { to_table: :users }
      t.integer :rating, null: false
      t.text :body

      t.timestamps
    end
    add_index :reviews, [ :contract_id, :reviewer_id ], unique: true

    create_table :shortlists do |t|
      t.references :job, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: { to_table: :users }
      t.references :freelancer, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :shortlists, [ :job_id, :client_id, :freelancer_id ], unique: true
  end
end
