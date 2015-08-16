# 在此可设置角色类名称、角色权限中间表等信息。

CanPlay::Config.setup do |config|
  config.user_class_name = 'User'
  config.role_class_name = 'Role'
  config.role_resources_middle_class_name = 'RoleResource'
  config.resource_class_name = 'Resource'
end