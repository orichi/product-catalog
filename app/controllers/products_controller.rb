class ProductsController < ApplicationController
  def index
  	@products = Product.all
  end

  def new
  	@product= Product.new
  end

   def create
    @product = Product.new(_product_params)
    @product.save
    redirect_to products_path
  end

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

  def show
  	@product = Product.find(params[:id])
  end

  def destroy
    product = Product.find(params[:id])
    product.destroy
    redirect_to products_path
  end


  private
    def _product_params
        params.require(:product).permit(:name, :price)
    end
end
