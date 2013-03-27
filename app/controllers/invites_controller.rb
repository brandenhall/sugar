# encoding: utf-8

class InvitesController < ApplicationController

  requires_authentication :except => [:accept]
  requires_user           :except => [:accept]
  requires_user_admin     :only   => [:all]

  respond_to :html, :mobile, :xml, :json

  before_filter :load_invite,    :only => [:show, :edit, :update, :destroy]
  before_filter :verify_invites, :only => [:new, :create]

  protected

    # Finds the requested invite
    def load_invite
      begin
        @invite = Invite.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_error 404 and return
      end
    end

    # Verifies that the user has available invites
    def verify_invites
      unless @current_user && @current_user.available_invites?
        respond_to do |format|
          format.any(:html, :mobile) do
            flash[:notice] = "You don't have any invites!"
            redirect_to online_users_url and return
          end
          format.any(:xml, :json) do
            render :text => "You don't have any invites!", :status => :method_not_allowed
          end
        end
      end
    end

  public

    # Show active invites
    def index
      respond_with(@invites = @current_user.invites.active)
    end

    # Show everyone's invites
    def all
      respond_with(@invites = Invite.find_active)
    end

    # Accept an invite
    def accept
      @invite = Invite.find_by_token(params[:id])
      session[:invite_token] = nil
      if @invite && @invite.expired?
        @invite.destroy
        flash[:notice] ||= "Your invite has expired!"
      elsif @invite
        session[:invite_token] = @invite.token
        redirect_to new_user_by_token_url(:token => @invite.token) and return
      else
        flash[:notice] ||= "That's not a valid invite!"
      end
      redirect_to login_users_url and return
    end

    # Create a new invite
    def new
      respond_with(@invite = @current_user.invites.new)
    end

    # Create a new invite
    def create
      @invite = @current_user.invites.create(params[:invite])
      if @invite.valid?
        begin
          Mailer.invite(@invite, accept_invite_url(:id => @invite.token)).deliver
          flash[:notice] = "Your invite has been sent to #{@invite.email}"
        rescue Net::SMTPFatalError, Net::SMTPSyntaxError
          flash[:notice] = "There was a problem sending your invite to #{@invite.email}, it has been cancelled."
          @invite.destroy
        end
        redirect_to invites_url and return
      else
        render :action => :new
      end
    end

    # def show
    # 	if verify_user(:user => @invite.user, :user_admin => true)
    # 		render :action => :edit
    # 	end
    # end
    #
    # def edit
    # 	verify_user(:user => @invite.user, :user_admin => true)
    # end
    #
    # def update
    # 	if verify_user(:user => @invite.user, :user_admin => true)
    # 		if @invite.update_attributes(params[:invite])
    # 			flash[:notice] = "Invite was updated"
    # 			redirect_to invites_url and return
    # 		else
    # 			render :action => :edit
    # 		end
    # 	end
    # end

    # Delete an invite
    def destroy
      if verify_user(:user => @invite.user, :user_admin => true)
        @invite.destroy
        flash[:notice] = "Your invite has been cancelled."
        redirect_to invites_url and return
      end
    end

end
