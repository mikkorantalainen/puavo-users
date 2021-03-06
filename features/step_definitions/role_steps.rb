Given /^the following roles:$/ do |roles|
  roles.hashes.each do |new_role|
    new_role[:puavoSchool] = @school.dn
    Role.create!(new_role)
  end
end

When /^I delete the (\d+)(?:st|nd|rd|th) role$/ do |pos|
  visit roles_url
  within("table tr:nth-child(#{pos.to_i+1})") do
    click_link "Destroy"
  end
end

Then /^I should see the following roles:$/ do |expected_roles_table|
  expected_roles_table.diff!(tableish('table tr', 'td,th'))
end

Given /^a new role with name "([^\"]*)" and which is joined to the "([^\"]*)" group$/ do
  |role_name, group_name|
  group = Group.find( :first,
                      :attribute => "displayName",
                      :value => group_name )
  role = Role.new
  role.displayName = role_name
  role.puavoSchool = @school.dn
  role.save
  role.groups << group
end

When /^I check "([^\"]*)" from roles$/ do |role_name|
  steps %Q{
    When I check field by id "role_#{role_name.to_s.downcase.gsub(/ /, '_')}"
  }
end

Then /^the memberUid should include "([^\"]*)" on the "([^\"]*)" role$/ do |uid, role_name|
  role_memberUid_include?(role_name, uid).should == true
end

Then /^the memberUid should not include "([^\"]*)" on the "([^\"]*)" role$/ do |uid, role_name|
  role_memberUid_include?(role_name, uid).should == false
end

private

def role_memberUid_include?(role_name, uid)
  role = Role.find( :first, :attribute => "displayName", :value => role_name )
  return Array(role.memberUid).include?(uid)
end
