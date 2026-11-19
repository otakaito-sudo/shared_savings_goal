module SavingGoals
  class ActivitiesController < ApplicationController
    before_action :require_login

    def index
      @goal=current_user.saving_goals.find(params[:saving_goal_id])
      @pagy, @activities=pagy(:offset,
        @goal.activities.includes(:actor, :target_user).recent, limit: 20)
    end
  end
end