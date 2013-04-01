require 'spec_helper'

describe PasswordResetsController do
  let(:user) { create(:user) }
  let(:password_reset_token) { create(:password_reset_token) }
  let(:expired_password_reset_token) { create(:password_reset_token, expires_at: 2.days.ago) }

  describe "GET new" do
    before { get :new }
    it { should respond_with(:success) }
    it { should render_template(:new) }
  end

  describe "POST create" do
    context "with an existing user" do
      before { post :create, email: user.email }
      it { should redirect_to(login_users_url) }
      it { should set_the_flash.to(/An email with further instructions has been sent/) }
      it { should assign_to(:user) }
      it { should assign_to(:password_reset_token) }
      specify { last_email.to.should == [user.email] }
      specify { last_email.body.encoded.should match(password_reset_with_token_url(
        assigns(:password_reset_token).id,
        assigns(:password_reset_token).token
      )) }
    end

    context "with a non-existant user" do
      before { post :create, email: "none@example.com" }
      it { should respond_with(:success) }
      it { should render_template(:new) }
      it { should_not assign_to(:password_reset_token) }
      it { should set_the_flash.now.to(/Couldn't find a user with that email address/) }
    end
  end

  describe "GET show" do
    context "with a valid token" do
      before { get :show, id: password_reset_token.id, token: password_reset_token.token }
      it { should respond_with(:success) }
      it { should render_template(:show) }
      it { should assign_to(:user) }
      it { should assign_to(:password_reset_token) }
    end

    context "without a valid token" do
      before { get :show, id: password_reset_token.id }
      it { should redirect_to(login_users_url) }
      it { should set_the_flash.now.to(/Invalid password reset request/) }
    end

    context "with an expired token" do
      before { get :show, id: expired_password_reset_token.id, token: expired_password_reset_token.token }
      it { should assign_to(:password_reset_token) }
      it { should redirect_to(login_users_url) }
      it { should set_the_flash.now.to(/Your password reset link has expired/) }
      specify { assigns(:password_reset_token).destroyed?.should be_true }
    end

    context "with a non-existant token" do
      before { get :show, id: 123, token: "456" }
      it { should redirect_to(login_users_url) }
      it { should set_the_flash.now.to(/Invalid password reset request/) }
    end
  end

  describe "PUT update" do
    context "with valid data" do
      before do
        put :update,
            id: password_reset_token.id,
            token: password_reset_token.token,
            user: { password: 'new password', confirm_password: 'new password' }
      end
      it { should set_the_flash.to(/Your password has been changed/) }
      it { should assign_to(:current_user) }
      it { should redirect_to(root_url) }
      specify { session[:user_id].should == password_reset_token.user.id }
      specify { assigns(:password_reset_token).destroyed?.should be_true }
    end

    context "without valid data" do
      before do
        put :update,
            id: password_reset_token.id,
            token: password_reset_token.token,
            user: { password: 'new password', confirm_password: 'wrong password' }
      end
      it { should respond_with(:success) }
      it { should render_template(:show) }
      it { should assign_to(:user) }
      it { should assign_to(:password_reset_token) }
      specify { assigns(:password_reset_token).destroyed?.should be_false }
    end

    context "without a valid token" do
      before do
        put :update,
            id: password_reset_token.id,
            user: { password: 'new password', confirm_password: 'new password' }
      end
      it { should redirect_to(login_users_url) }
      it { should set_the_flash.now.to(/Invalid password reset request/) }
    end

    context "with an expired token" do
      before do
        put :update,
            id: expired_password_reset_token.id,
            token: expired_password_reset_token.token,
            user: { password: 'new password', confirm_password: 'new password' }
      end
      it { should assign_to(:password_reset_token) }
      it { should redirect_to(login_users_url) }
      it { should set_the_flash.now.to(/Your password reset link has expired/) }
      specify { assigns(:password_reset_token).destroyed?.should be_true }
    end
  end
end
