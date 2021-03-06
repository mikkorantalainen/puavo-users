Given /^I am logged in as "([^\"]*)" with password "([^\"]*)"$/ do |login, password|
  visit login_path
  fill_in("login", :with => login)
  fill_in("password", :with => password)
  click_button("Login")
end

Given /^I am logged out$/ do
  visit logout_path
end

Given /^the following users:$/ do |users|
  salt = "testsalt"
  users.hashes.each do |u|
    roles = nil
    if u["roles"]
      roles = u["roles"].split(/,[ ]*/) 
      u.delete("roles")
    end
    user = User.new(u)
    user.puavoSchool = @school.dn
    user.userPassword = "{SSHA}" + 
      Base64.encode64(Digest::SHA1.digest(u["password"] + salt) + salt).chomp!
    user.save
    if roles
      roles.each do |role_name|
        Role.find( :first,
                   :attribute => "displayName",
                   :value => role_name ).members << user
      end
    end
    user.update_associations
  end
end

When /^I set in "([^\"]*)" with "([^\"]*)" to "([^\"]*)"$/ do |method, text, username|
  user = User.find_by_username(username)
  user.send(method.to_s + "=", text)
end

Then /^I should get "([^\"]*)" with "([^\"]*)" from "([^\"]*)"$/ do |text, method, username|
  User.find_by_username(username).send(method).should == text
end

Then /^I should see the following users:$/ do |users_table|
  users_table.diff!(tableish('table#validate_users_list tr', 'td,th'))
end

When /^I fill test data into user forms$/ do
  steps %Q{
    And I fill in "Given names" with "Ben Lars"
    And I fill in "Nickname" with "Ben"
    And I fill in "Lastname" with "Mabey"
    And I fill in "Login" with "ben"
    And I fill in "School start year" with "2005"
    And I check "Student"
    And I check "Employee"
    And I check "Library walk in"
    And I check "Guardian"
    And I check "Locked"
    And I fill in "Email(s)" with "ben@some.com"
    And I fill in "Phone number(s)" with "+3581234567890"
    And I fill in "tags" with "english programming"
    And I fill in "Password" with "secret"
    And I fill in "Password confirmation" with "secret"
  }
end

When /^I should see same test data on the user page$/ do
  steps %Q{
    And I should see "Ben Lars"
    And I should see "Ben"
    And I should see "Mabey"
    And I should see "ben"
    And I should see "2005"
    And I should see "Student"
    And I should see "Employee"
    And I should see "Library walk-in"
    And I should see "Guardian"
    And I should see "Locked"
    And I should see "ben@some.com"
    And I should see "+3581234567890"
    And I should see "english"
    And I should see "programming"
}
end
Then /^I should see the following special ldap attributes on the "([^\"]*)" object with "([^\"]*)":$/  do
  |model, key, table|
  case model
  when "User"
    object = User.find( :first, :attribute => "uid", :value => key )
  when "School"
    object = School.find( :first, :attribute => "displayName", :value => key )
  when "Group"
    object = Group.find( :first, :attribute => "displayName", :value => key )
  end
  table.rows_hash.each do |attribute, regexp|
    regexp = eval(regexp)
    object.send(attribute).to_s.should =~ /#{regexp}/
  end
end

Given /^I am set the "([^\"]*)" role for "([^\"]*)"$/ do |role, uid|
  steps %Q{
    And I am on the edit user page with "#{uid}"
    And I check "#{role}" from roles
    And I press "Update"
}
end
