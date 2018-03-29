require 'rails_helper'

RSpec.describe ProductsController, type: :controller do

  describe "GET #index" do
    it "returns http success" do
      FactoryBot.create(:product, {name: "Nexus 5", price: 199})
      get :index
      expect(response).to have_http_status(:success)
    end
  end

end
