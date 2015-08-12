class ActionController::Base
  include Consul::Controller
  current_power do
    Power.new(current_user)
  end
end