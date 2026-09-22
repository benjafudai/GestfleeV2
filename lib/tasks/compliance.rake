namespace :compliance do
  desc "Check document expirations and notify admins"
  task check_expirations: :environment do
    ComplianceChecker.call
  end
end
