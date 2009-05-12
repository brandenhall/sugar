require 'digest/sha1'

class Invite < ActiveRecord::Base
	belongs_to :user
	validates_presence_of :email, :user_id
	
	DEFAULT_EXPIRATION = 7.days

	validate do |invite|
		invite.token ||= Invite.unique_token
		if User.exists?(:email => invite.email)
			invite.errors.add(:email, 'is already registered!')
		end
		if Invite.find_valid.map{|i| i.email}.include?(invite.email)
			invite.errors.add(:email, 'has already been invited!')
		end
	end
	
	before_create do |invite|
		invite.expires_at = Time.now + Invite.expiration_time
		if invite.valid?
			invite.user.revoke_invite!
		end
	end
	
	before_destroy do |invite|
		invite.user.grant_invite!
	end
	
	class << self
		# Makes a unique random token.
		def unique_token
			token = nil
			token = Digest::SHA1.hexdigest(rand(65535).to_s + Time.now.to_s) until token && !self.exists?(:token => token)
			token
		end
		
		# Gets the default expiration time.
		def expiration_time
			DEFAULT_EXPIRATION
		end
		
		# Finds valid invites
		def find_valid
			self.find(:all, :conditions => ['expires_at > ?', Time.now], :order => 'created_at DESC')
		end
	end
	
	# Has this invite expired?
	def expired?
		(Time.now <= self.expires_at) ? false : true
	end
end
