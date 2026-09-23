class RemoveTwoFactorEmailFromUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :otp_code_digest, :string
    remove_column :users, :otp_sent_at, :datetime
    remove_column :users, :otp_attempts, :integer, default: 0, null: false
    remove_column :users, :otp_remember_digest, :string
    remove_column :users, :otp_remember_expires_at, :datetime
  end
end
