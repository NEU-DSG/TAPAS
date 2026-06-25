class AccountDeletionMailer < ApplicationMailer
  def contributor_files_notification(owner, core_files, deleted_user_display)
    @owner = owner
    @core_files = core_files
    @deleted_user_display = deleted_user_display
    mail(to: owner.email, subject: "TAPAS: files transferred to you after account deletion")
  end
end
