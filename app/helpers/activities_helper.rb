module ActivitiesHelper
  def activity_message(activity)
    actor =  activity.actor.name
    target = activity.target_user&.name
    amount = activity.amount&&number_to_currency(activity.amount, unit: "円", precision: 0)

    case activity.kind.to_sym
    when :deposit_requested then "#{actor}さんが#{amount}の入金を申請しました"
    when :deposit_confirmed then "#{actor}さんが#{amount}の入金を確認しました"
    when :deposit_rejected then "#{actor}さんが#{amount}の入金を却下しました"
    when :deposit_remanded then "#{actor}さんが#{amount}の入金を差し戻しました"
    when :deposit_resubmitted then "#{actor}さんが#{amount}で再申請しました"
    when :member_joined then "#{actor}さんが参加しました"
    when :member_removed then "#{actor}さんが#{target}さんを外しました"
    when :goal_achieved then "目標金額を達成しました"
    end
  end
end
