class AddTwoFactorEmailToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :otp_code_digest, :string
    add_column :users, :otp_sent_at, :datetime
    add_column :users, :otp_attempts, :integer, default: 0, null: false
    add_column :users, :otp_remember_digest, :string
    add_column :users, :otp_remember_expires_at, :datetime
  end
end
