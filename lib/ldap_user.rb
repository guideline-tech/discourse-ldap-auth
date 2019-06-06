class LDAPUser
  attr_reader :name, :email, :username, :user

  def initialize (auth_info)
    @name = auth_info[:name]
    @email = auth_info[:email]
    @username = auth_info[:nickname]
    @user = SiteSetting.ldap_lookup_users_by == 'username' ? User.find_by_username(@username) : User.find_by_email(@email)
    set_user_groups(auth_info[:groups])
  end

  def auth_result
    result = Auth::Result.new
    result.name = @name
    result.username = @username
    result.email = @email
    result.user = @user
    result.omit_username = true
    result.email_valid = true
    return result
  end

  def account_exists?
    return !@user.nil?
  end

  private
  def set_user_groups(user_groups)
    return if user_groups.nil?
    # user account must exist in order to create user groups
    unless self.account_exists?
      @user = User.create!(name: self.name, email: self.email, username: self.username)
      @user.activate
    end
    groups = users_default_group_memberships
    user_groups.each do |group_name|
      group = Group.find_by(name: group_name)
      groups << group unless group.nil?
    end
    @user.groups = groups
  end

  def users_default_group_memberships
    if @user.groups
      groups = @user.groups.select{|g| ['admins','moderators','staff','trust_level_0','trust_level_1','trust_level_2','trust_level_3','trust_level_4'].include?(g.name)}
    else
      groups = []
    end
    groups ? groups : []
  end
end
