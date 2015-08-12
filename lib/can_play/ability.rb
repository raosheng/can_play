require 'cancancan'
class Ability
  include CanCan::Ability
  attr_accessor :user

  def initialize(user)
    self.user = user||User.new
    Role.all.each do |role|
      next unless user.has_role?(role.name)
      role.role_resources.each do |role_resource|
        resource = Resource.find_by_name(role_resource.resource_name)
        if resource[:behavior]
          block = resource[:behavior]
          can resource[:verb], resource[:object] do |object|
            block.call(user, object)
          end
        else
          can resource[:verb], resource[:object]
        end
      end
    end
  end
end