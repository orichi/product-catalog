## TDD手把手
## 在mongoid项目中实验tdd 
#### Note: ruby 2.2.1， rails 4.2.x，详细请看gemfile.lock
#### capybara[文档地址](https://github.com/teamcapybara/capybara#using-capybara-with-rspec)
#### rspec[文档地址](https://relishapp.com/rspec/rspec-rails/docs/model-specs)
### 生成项目

避免生成active_record 文件，添加参数 `--skip-active-record` 或者 `-O`

完整的项目生成脚本如下

`rails new product-catalog -T -O`

然后，打开 *Gemfile* 添加我们需要的gem包。用 *rspec-rails* 给这个项目写测试。用 *Guard* 去做自动测试。Guard检测文件系统的改动事件。使用 *Capybara* 去模仿用户操作-打开页面，然后自动测试。*mongoid* 和 *bson-ext* 去使用mongoDB。 *factory_bot_rails* 去生产模型对象。

最终改动的gemfile部分如下。

```
   source 'http://gems.github.com
gem 'mongoid', github: 'mongoid/mongoid'
gem 'bson_ext'

group :development, :test do
    gem 'rspec-rails'
    gem 'guard-rspec'
    gem 'capybara'
    gem 'factory_bot_rails'
end
```

然后执行打包命令 bundle install 或者 bundle

开始构建应用之前，需要rspec, capybara初始化。

* 初始化rspec

	`rails g rspec:install`

* 初始化 capybara, 在test helper文件里添加

	`require 'capybara/rails'`

	如果是rspec3.x以上版本，需要添加支持在 spec_helper.rb里

	`require 'capybara/rspec'`

* `factory_bot_rails` 默认的夹具目录在 test/factories或者 spec/factories内
	
	安装以后，生成器生成model的时候，默认会生成一个夹具factory对象，如下

	```
	FactoryBot.define do
	  factory :product do
	    name "MyString"
	    price 1
	  end
	end
	
	```

	如果不需要这个功能，可以在application.rb里屏蔽掉
	
	```
	config.generators do |g|
	  g.factory_bot false
	end
	```
	也可以更改夹具目录

	```
	config.generators do |g|
	  g.factory_bot dir: 'custom/dir/for/factories'
	end
	```
	
	rspec套件支持设定,Rails环境
	
	```
	# spec/support/factory_bot.rb
	RSpec.configure do |config|
	  config.include FactoryBot::Syntax::Methods
	end

	```
	在spec/rails_helper.rb 中添加

	`require 'support/factory_bot'`

给测试驱动开发创建一个集成测试文件

```
mkdir -p spec/feature/
touch product_display_spec.rb
```

在 `spec/feature/product_display_spec.rb` 中加入测试框架

```
require 'rails_helper'
RSpec.describe "ProductCatalogs", type: :feature do
	# TODO

end
```

下一步，初始化 guard，一个可以自动跑测试case的程序。

`guard init rspec`

然后启动它测试

`guard`



## 开始构建应用

### 展示产品列表

在集成测试(请求)文件`spec/requests/product_catelog_spec.rb`中 书写

```
describe "GET /products" do
    it "display some products list" do
        visit products_path	
        expect(page).to have_content 'Nexus 5'
    end
 end
``` 

保存的时候，自动测试 *guard* 提示

```
Failures:

  1) ProductCatalogs GET /product(s)  show products list
     Failure/Error: visit products_path
     ...
```

提示路由出错，我们没有声明相应的路由，下面打开 `config/routes.rb`, 添加路由记录

`rousources :products`

然后打开 *guard* 终端，发现错误是

```
NameError:
     #   uninitialized constant ProductsController
```

没有ProductsController 常量，然后我们新建一个controller

`rails g controller products index`

然后我们检查 guard，

```
ProductCatalogs GET /product(s)  show products list
	Failure/Error: page.should have_content 'Nexus 5'
       expected to find text "Nexus 5" in "Products#index Find me in app/views/products/index.html.erb"
     # ./spec/feature/products_display_spec.rb:7:in `block (3 levels) in <top (required)>'
```

为了在页面上看到 "Nexus 5", 我们需要把数据存进数据库。首先声明一个model

`rails g model product name:string price:integer`

因为声明了使用mongoid，所以 生成器会自动关联mongoid，模型代码大概如下

```
class Product
  include Mongoid::Document
  field :name, type: String
  field :price, type: Integer
end
```

然后我们需要声明一个 Mongoid配置，执行如下命令

`rails g mongoid:config`

在 `spec/requests/product_catelog_spec.rb` 的测试代码中模拟一个product记录

```
describe "GET /product(s) " do
	it 'show products list' do
		### add one product-document
		build(:product, {name: "Nexus 5", price: 199}) 
		visit products_path
		expect(page).to have_content 'Nexus 5'
	end
end

如果需要多个调用，需要声明为setup

setup {
	build(:product, {name: "Nexus 5", price: 199}) 
}

```

然后再看 guard 终端

```
11:12:26 - INFO - Running: spec/feature/products_display_spec.rb
.

Finished in 0.22005 seconds (files took 1.82 seconds to load)
1 example, 0 failures
```
测试通过


### 创建一个product
下一步我们去添加一个产品，大概步骤如下

```
it "add a product into product catalog" do
    visit products_path
    click_link 'New Product'
    expect(current_path).to eql(new_product_path)
    fill_in :product_name, :with =>  'Nexus 5'
    fill_in :product_price, :with => '30000'
    click_button 'Save Product'
    expect(current_path).to eql(products_path)
end
```

要实现这个功能，我们首先在index页面上添加一个链接

`<%= link_to 'New Product', new_product_path%>`

然后查看 guard

```
 ProductCatalogs add a product into product catalog
     Failure/Error: click_link 'New Product'
     
     AbstractController::ActionNotFound:
       The action 'new' could not be found for ProductsController
```

提示new action木有，我们创建new action及相应的页面

```
def new
  	@product= Product.new
  end

   def create
    @product = Product.new(_product_params)
    @product.save
	 redirect_to products_path
  end
  
  private
    def _product_params
        params.require(:product).permit(:name, :price)
    end
  
  
#products/new.html.erb  
<%= form_for :product, url: products_path do |f|%>
    <%= f.label :Name %>
    <%= f.text_field :name  %>

    <%= f.label :Price %>
    <%= f.text_field :price %>

    <%= f.submit %>
<% end %>
```
再看guard，

```
Finished in 0.2993 seconds (files took 1.79 seconds to load)
7 examples, 0 failures, 3 pending
```

### 展示商品页

先写测试代码

```
it "show details of a product" do
        @product = Product.create :name => 'Nexus 4', :price => 25000
        visit product_path(@product)
        expect(page).to have_content 'Nexus 4'
        expect(page).to have_content '25000'    
end
```
添加action

```
def show
	@product = Product.find(params[:id])
end
```
添加页面 show.html.erb

```
<h1>Product Details</h1>
<p>
     <strong>Name:</strong>
     <%= @product.name %>
</p>

<p>
      <strong>Price:</strong>
      <%= @product.price %>
</p>
```

### 更新产品
如果我们需要多次使用@product对象，我们可以把它放在一个before block里边，然后测试完后清除

```
 # 在spec.rb文件内添加
 before do
    @product = Product.create :name => 'Nexus 5', :price => 30000
 end

 after  do
    Product.delete_all 
 end
 
# index.html.erb 页面修改成下面的
<% @products.each do |product| %>
    <tr id="product_<%= product.id %>">
        <td><%= product.name %></td>
        <td><%= product.price %></td>
        <td><%= link_to 'Edit', edit_product_path(product) %></td>
    </tr>   
<% end %>

# controller里添加
def edit
      @product  = Product.find(params[:id])
end

def update
	product = Product.find(params[:id])
	if product.update(_product_params)
	  redirect_to products_path
	else
	  render 'edit'
	end
end

# 添加edit.html.erb


<%= form_for :product, url: product_path(@product), method: :patch do |f|%>

    <%= f.label :name %>
    <%= f.text_field :name  %>

    <%= f.label :price %>
    <%= f.text_field :price %>

    <%= f.submit %>
<% end %>

```

然后看guard里的，如果有别example的出错，那么修改一下别的example

### 删除产品
先写测试流程
```
it "delete a product" do
        visit products_path
        find("#product_#{@product.id}").click_link 'Delete'
        page.should have_no_content 'Nexus 3'
        page.should have_no_content 'Nexus 3'
        current_path.should == products_path
end
```

index.html.erb内加入链接

`<td><%= link_to 'Delete', product_path(product), method: :delete, data: {confirm: 'Are you sure?'} %></td>`


controller内加入

```
def destroy
    product = Product.find(params[:id])
    product.destroy
    redirect_to products_path
  end
```

再看guard 终端

```
12:25:26 - INFO - Running: spec/feature/products_display_spec.rb
.....

Finished in 0.35467 seconds (files took 1.77 seconds to load)
5 examples, 0 failures
   
```   


## mina+puma  部署

添加

```
gem mina
gem puma
gem 'mina-puma'
```

服务器组件

```
rvm 
ruby 
libxslt-dev libxml2-dev
nginx
nodejs
mongodb
# 等等，视项目情况而定
```

```
ssh-copy-id -i .ssh/id_ras.pub user@ip
```

### mina部署步骤
mina setup

mina deploy

mina puma:[start|restart|stop]

nginx server 配置

```
# /etc/nginx/sites-enabled/product_i

  upstream deploy {
    server unix:///var/www/product/shared/tmp/sockets/product.sock;
  }

  server {
      listen 80;
      server_name product.i; # change to match your URL
      root /var/www/product/current/public; # I assume your app is located at this location

      location / {
          proxy_pass http://deploy; # match the name of upstream directive which is defined above
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      }

      location ~* ^/assets/ {
          # Per RFC2616 - 1 year maximum expiry
          expires 1y;
          add_header Cache-Control public;
                  # Some browsers still send conditional-GET requests if there's a
          # Last-Modified header or an ETag header even if they haven't
          # reached the expiry date sent in the Expires header.
          add_header Last-Modified "";
          add_header ETag "";
          break;
      }
}

```
