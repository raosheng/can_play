can_plan集成了cancancan和consul的功能，使用DSL描述用户对单个类的实例或某个类的操作权限，及可获取的条目的基础的relation对象.

## 安装方式

### 安装cancancan

cancancan的使用请参见cancancan主页，在此我们安装后，不需要设置Ability文件，can_play在内部集成了这些设置。
### 安装consul

consul的使用请参见consul主页，在此我们安装后，不需要设置power文件，也无需在controller中设置current_power，can_play在内部集成了这些设置。
### can_play安装
在gemfile中加入can_play的github地址来安装。

安装后执行如下命令

```
rails generate can_play:install
```

会在initializer和locales文件夹下生成文件。
initializer文件夹下的can_play.rb是can_play的基本配置文件。
locales下的can_play.zh-Cn.yml文件用于描述权限名称。

### DSL文件描述权限
dsl文件写法如下：

	#用哪个类用来描写权限，可在intializer下的can_play.rb文件下描写。
	class Resource
	  include CanPlay

	  # 所有limit块、collection块和member块中都注入了user这个变量，指向当前登录用户，可直接使用。

	  group Contract do |klass|

	  	# 描述某个用户可以查看到哪些合同条目。
	    limit do
	      if user.is_admin?
	        klass.all
	      elsif user.role? '供应商'
	        klass.where(emall: user.emall)
	      elsif user.role? '采购人'
	        klass.where(department: user.department)
	      else
	        klass.none
	      end
	    end

		# 描述某个用户可以是否而已查看合同列表、创建合同。
	    collection [:list, :create], klass do
	      user.is_admin?
	    end

		# 描述某个用户可以是否可以查看、更新某个合同。
	    member [:read, :update], klass do |obj|
	      if user.is_admin?
	        true
	      elsif user.role? '供应商'
	        obj.emall.is? user.emall
	      elsif user.role? '采购人'
	        obj.department.is? user.department
	      else
	        false
	      end
	    end

		# 描述某个用户可以是否可以删除、终止某个合同。
	    member [:delete, :terminate], klass do |obj|
	      user.is_admin?
	    end
	  end

	  group Project do |klass|

	    limit do
	      if user.is_admin?
	        klass.all
	      else
	        klass.none
	      end
	    end

	    collection [:list, :create], klass do
	      user.is_admin?
	    end

	    member [:read, :update, :delete, :create_later_documents], klass do |obj|
	      user.is_admin?
	    end
	  end
  	end

### 和角色类之间建立关联

此处的DSL相当于在数据库中的resouces表，记录了所有权限。我们需要通过role_resources这样的中间表，建立角色和资源之间的关联。因此在数据库建立中间表role_resources,使用一个resource_name字段来跟DSL中的权限、资源进行关联。我们再前端页面，只需要调用Resource.grouped_resources_with_chinese_desc就可获取到所有DSL文件中描述的所有权限以及中文描述。再在controller和view中创建权限和role的关联即可（往role_resources中间表写条目）。