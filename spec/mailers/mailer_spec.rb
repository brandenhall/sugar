require "spec_helper"

describe Mailer do

  let(:user)      { create(:new_user) }
  let(:invite)    { create(:invite) }
  let(:login_url) { "http://example.com/login" }

  before do
    Sugar.config(:forum_name, "Sugar")
    Sugar.config(:mail_sender, "test@example.com")
  end

  describe "invite" do

    let(:mail) { Mailer.invite(invite, login_url) }

    specify { mail.subject.should == "#{invite.user.realname} has invited you to Sugar!" }
    specify { mail.to.should == [invite.email] }
    specify { mail.from.should == ["test@example.com"] }

    describe "its body" do

      subject { mail.body.encoded }

      it { should match(Sugar.config(:forum_name)) }
      it { should match(invite.user.realname) }
      it { should match(login_url) }

      context "when invite has message" do
        let(:invite) { create(:invite, message: "My message") }
        it { should match("My message") }
      end

    end

  end

  describe "new_user" do

    let(:mail) { Mailer.new_user(user, login_url) }

    specify { mail.subject.should == "Welcome to Sugar!" }
    specify { mail.to.should == [user.email] }
    specify { mail.from.should == ["test@example.com"] }

    describe "its body" do

      subject { mail.body.encoded }

      context "when signed up with password" do

        it { should match(user.username) }
        it { should match(login_url) }

      end

      context "when signed up with OpenID" do

        let(:user) { create(:new_user, openid_url: "http://example.com/") }

        it { should match(user.openid_url) }
        it { should match(user.username) }

      end

    end

  end

  describe "password_reset" do
    let(:mail) { Mailer.password_reset("user@example.com", "http://example.com") }
    subject { mail }

    its(:subject) { should == "Password reset for Sugar" }
    its(:to) { should == ["user@example.com"] }
    its(:from) { should == ["test@example.com"] }
    its("body.encoded") { should match("http://example.com") }
  end

end