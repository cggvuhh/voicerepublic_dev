require 'rails_helper'

describe Api::SessionsController do

  before do
    @user =  FactoryGirl.create(:user, {password: '123123', password_confirmation: '123123'})
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "Sign In" do

    describe 'successful' do
      before do
        allow(request.env['warden']).to receive_messages :authenticate! => @user
        allow(controller).to receive_messages :current_user => @user
      end

      it "sends the authentication_token" do
        post :create, { email: @user.email, password: '123123', format: 'json' }
        res = JSON.parse(response.body)
        expect(res).to_not be_empty
        expect(res['authentication_token']).to_not be_empty
        # Should not leak too much information
        expect(res['encrypted_password']).to be_nil
      end

      it 'sends a list of all series of the user' do
        3.times { FactoryGirl.create :series, user: @user }
        post :create, { email: @user.email, password: '123123', format: 'json' }
        res = JSON.parse(response.body)
        expect(res).to_not be_empty
        expect(res['list_of_series']).to_not be_empty

        series_titles = Hash(res['list_of_series']).values
        @user.series.pluck(:title).each do |title|
          expect(series_titles).to include(title)
        end

      end
    end

    describe 'failure' do
      it "via json" do
        post :create,
          { user: { email: @user.email, password: 'wrong_pwd' },
            format: 'json' }
          res = JSON.parse(response.body)
          expect(res).to_not be_empty
          expect(res['errors']).to_not be_empty
          expect(response.status).to be(401)
      end
    end
  end

end
