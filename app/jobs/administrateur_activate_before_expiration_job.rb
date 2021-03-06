class AdministrateurActivateBeforeExpirationJob < CronJob
  self.cron_expression = "0 8 * * *"

  def perform(*args)
    Administrateur
      .includes(:user)
      .inactive
      .where(created_at: 3.days.ago.all_day)
      .each { |a| a.user.remind_invitation! }
  end
end
