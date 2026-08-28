class ChangeUserRolesToSystemPrivileges < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE users
      SET role = CASE role
        WHEN 2 THEN 1
        WHEN 3 THEN 2
        ELSE 0
      END
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
