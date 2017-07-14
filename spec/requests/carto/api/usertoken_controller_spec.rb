# encoding: utf-8

require_relative '../../../spec_helper'

describe Carto::Api::UsertokenController do
  describe '#User token API tests' do

    before(:all) do
      @user = FactoryGirl.create(:valid_user)
    end

    before(:each) do
      bypass_named_maps
      delete_user_data @user
      @table = create_table(user_id: @user.id)
    end

    after(:all) do
      bypass_named_maps
      @user.destroy
    end

    let(:params) { { api_key: @user.api_key, table_id: @table.name, user_domain: @user.username } }

    it "Create a new token and get the entry" do

      post_json api_v1_tables_token_create_url(params) do |response|
        response.status.should be_success
        response.body[:user].should == @user.username
        response.body[:permission].should == 'r'
        params[:user_token] = response.body[:user_token]
      end

      get_json api_v1_tables_token_show_url(params) do |response|
        response.status.should be_success
        response.body[:user].should == @user.username
        response.body[:permission].should == 'r'
        response.body[:user_token].should == params[:user_token]
      end
    end

    it "Create a new token and give specific permission" do
      permission = 'rw'
      post_json api_v1_tables_token_create_url(params.merge({:permission => permission})) do |response|
        response.status.should be_success
        response.body[:user].should == @user.username
        response.body[:permission].should == permission
        params[:user_token] = response.body[:user_token]
      end

      get_json api_v1_tables_token_show_url(params) do |response|
        response.status.should be_success
        response.body[:user].should == @user.username
        response.body[:permission].should == permission
        response.body[:user_token].should == params[:user_token]
      end
    end

    it "Get an entry that doesn't exist" do
      get_json api_v1_tables_token_show_url(params.merge({:user_token => "nonExistingToken"})) do |response|
        response.status.should == 404
      end
    end

    it "Create a token and update the permission granted on a token" do

      post_json api_v1_tables_token_create_url(params) do |response|
        response.status.should be_success
        response.body[:user].should == @user.username
        response.body[:permission].should == 'r'
        params[:user_token] = response.body[:user_token]
      end

      new_permission = 'rw'
      put_json api_v1_tables_token_update_url(params.merge({:permission => new_permission})) do |response|
        response.status.should be_success
        response.body[:user].should == @user.username
        response.body[:permission].should == new_permission
        response.body[:user_token].should == params[:user_token]
      end
    end

    it "Update permissions on an entry" do
      user_token = "testToken"
      $users_metadata.HMSET(user_token, "user", @user.username, "permission", 'r')

      new_permission = 'rw'
      put_json api_v1_tables_token_update_url(params.merge({:permission => new_permission, :user_token => user_token})) do |response|
        response.status.should be_success
        response.body[:user].should == @user.username
        response.body[:permission].should == new_permission
        response.body[:user_token].should == user_token
      end
    end

    it "Update an entry that doesn't exist" do
      put_json api_v1_tables_token_update_url(params.merge(:user_token => "nonExistingToken")) do |response|
        response.status.should == 404
      end
    end

    it "Delete a token and try to get it" do

      user_token = "testToken"
      $users_metadata.HMSET(user_token, "user", @user.username, "permission", 'r')

      delete_json api_v1_tables_token_destroy_url(params.merge({:user_token => user_token})) do |response|
        response.status.should be_success
        response.body[:success].should == true
      end

      get_json api_v1_tables_token_show_url(params.merge({:user_token => user_token})) do |response|
        response.status.should == 404
      end
    end

    it "Delete a token that doesn't exists" do
      user_token = "testToken"

      delete_json api_v1_tables_token_destroy_url(params.merge({:user_token => user_token})) do |response|
        response.status.should be_success
        response.body[:success].should == true
      end
    end
  end
end
