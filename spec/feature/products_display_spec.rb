require 'rails_helper'
RSpec.describe "ProductCatalogs", type: :feature do

	before do
        @product = Product.create :name => 'Nexus 3', :price => 10000
	end

	 after  do
	    Product.delete_all 
	 end

	describe "GET /product(s) " do
		it 'show products list' do
			visit products_path
			expect(page).to have_content 'Nexus 3'
		end
	end


	it "add a product into product catalog" do
        visit products_path
        click_link 'New Product'
        expect(current_path).to eql(new_product_path)
        fill_in :product_name, :with =>  'Nexus 5'
        fill_in :product_price, :with => '30000'
        click_button 'Save Product'
        expect(current_path).to eql(products_path)
   end

   it "show details of a product" do
        @product = Product.create({name: "Nexus 4", price: 129})
        visit product_path(id: @product.id)
        expect(page).to have_content 'Nexus 4'
        expect(page).to have_content '129'    
	end

	it "edit a Product details" do
        visit products_path
        find("#product_#{@product.id}").click_link 'Edit'
        expect(current_path).to eql edit_product_path(@product)
        expect(find_field('Name').value).to eql 'Nexus 3'
        expect(find_field('Price').value).to eq '10000'
        fill_in 'Price', :with => '25000'
        click_button 'Save Product'
        expect(page).to have_content '25000'
        visit products_path
        expect(page).to have_no_content '10000'
  end 

  it "delete a product" do
        visit products_path
        find("#product_#{@product.id}").click_link 'Delete'
        expect(page).to have_no_content 'Nexus 3'
        expect(page).to have_no_content 'Nexus 5'
        expect(current_path).to eql products_path
end
end