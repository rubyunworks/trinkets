#

class ActionPlan

  def intialize
    @targets
    @actions
  end

  def plan( *targets, &action )
    @targets << targets
    @actions << action
  end

  def act
    @action.each_with_index do |act,i|
      act.call(*targets[i])
    end
  end

end
