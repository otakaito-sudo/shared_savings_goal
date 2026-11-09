class InvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation=invitation
    @goal=invitation.saving_goal
    @url=invitation_url(invitation, token: invitation.token)

    mail to: invitation.email, subject: "「#{@goal.name}」への招待が届いています"
  end
end
