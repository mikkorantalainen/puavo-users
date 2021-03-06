require 'sha1'
require 'base64'

Before do |scenario|
  test_organisation = Organisation.find('example')
  default_ldap_configuration = ActiveLdap::Base.ensure_configuration
  # Setting up ldap configuration
  LdapBase.ldap_setup_connection( test_organisation.ldap_host,
                                  test_organisation.ldap_base,
                                  default_ldap_configuration["bind_dn"],
                                  default_ldap_configuration["password"] )

  # Clean Up LDAP server: destroy all schools, groups and users
  User.all.each do |u|
    u.destroy
  end
  Group.all.each do |g|
    g.destroy
  end
  School.all.each do |s|
    s.destroy
  end
  Role.all.each do |p|
    p.destroy
  end
end

Given /^I am logged in as "([^\"]*)" organisation owner$/ do |organisation_name|
  organisation = Organisation.find(organisation_name)
  # Create owner user
  # FIXME, owner must be create before (initalization ldap server)
  password = "test"
  salt = "test"
  u = User.new
  u.homeDirectory = "/home/test"
  u.sn = "test"
  u.givenName = "test"
  u.uid = "test"
  u.gidNumber = "10006"
  u.userPassword = "{SSHA}" + Base64.encode64(Digest::SHA1.digest(password + salt) + salt).chomp!
  u.puavoSchool = organisation.schools.first.dn
  u.save

  organisation.schools.each do |s|
    s.puavoSchoolAdmin = [u.dn]
    s.save
  end

  visit new_user_session_path
  fill_in("login", :with => u.uid)
  fill_in("password", :with => password)
  click_button("Login")
end

Given /^a new ([^\"]*) with names (.*) on the "([^\"]*)" organisation$/ \
do |names_of_the_models, values, organisation|
  Organisation.find(organisation)
  models = names_of_the_models.split(' and ')
  values = values.split(', ').map { |value| value.tr('"', '') }
  models_value = Hash.new
  index = 0
  models.each do |model|
    models_value[model] = values[index]
    index += 1
  end

  if models_value.has_key?('school')
    @school = School.new( :displayName =>  models_value['school'],
                          :cn => models_value['school'].downcase.gsub(/[^a-z0-9]/, "")
                          )
    @school.puavoSchoolAdmin = ["cn=admin,o=puavo"]
    @school.save
  end
  if models_value.has_key?('group')
    @group = Group.create( :displayName => models_value['group'],
                           :cn => models_value['group'].downcase.gsub(/[^a-z0-9]/, "") )
    @school.groups << @group
  end
end

When /^I check field by id "([^\"]*)"$/ do |field_id|
  check( field_with_id(field_id) )
end

Given /^I am on ([^\"]+) with "([^\"]*)"$/ do |page_name, value|
  case page_name
  when /user page$/
    user = User.find(:first, :attribute => "uid", :value => value)
    case page_name
    when /edit/
      visit edit_user_path(@school, user)
    when /show/
      visit user_path(@school, user)
    end
  when /school page$/
    school = School.find( :first, :attribute => "displayName", :value => value )
    visit school_path(school)
    #visit path_to(page_name) # FIXME
  when /group page/
    group = Group.find( :first, :attribute => "displayName", :value => value )
    case page_name
    when /the group page/
      visit group_path(@school, group)
    when /the edit group page/
      visit edit_group_path(@school, group)
    end
  when /role page/
    role = Role.find( :first, :attribute => "displayName", :value => value )
    case page_name
    when /show/
      visit role_path(@school, role)
    end
  else
    raise "Unknow page: #{page_name}"
  end
end

When /^I get on ([^\"]+) with "([^\"]*)"$/ do |page_name, value| 
  case page_name
  when /user JSON page$/
    @json_user = User.find(:first, :attribute => "uid", :value => value)
    case page_name
    when /show/
      visit "/users/" + @json_user.id.to_s + ".json"
    end
  end
end

Then /^I should see JSON "([^\"]*)"$/ do |json_string|
  response_hash = ActiveSupport::JSON.decode(response.body)
  string_hash = ActiveSupport::JSON.decode(json_string)
  model_key = string_hash.keys.first
  string_hash[model_key].each do |key, value|
    if key == "tags"
      value = sort_tags(value)
      response_hash[model_key][key] = sort_tags(response_hash[model_key][key])
    end
    value.should == response_hash[model_key][key]
  end
end

private

def sort_tags(tags)
  return tags.split(TagList.delimiter).sort.join(TagList.delimiter)
end

When /^I fill in textarea "([^\"]*)" with "([^\"]*)"$/ do |field, value|
  fill_in(field, :with => value)
end

Then /^I should see the following:$/ do |values|
  # FIXME: the first value of table is ignored
  values.rows.each do |value|
    Then %{I should see "#{value}"}
  end
end

Then /^named the "([^\"]*)" field should contain "([^\"]*)"$/ do |field, value|
  field_named(field).value.should =~ /#{value}/
end

Then /^id the "([^\"]*)" field should contain "([^\"]*)"$/ do |field_id, value|
  field_with_id(field_id).value.should =~ /#{value}/
end

Then /^id the "([^\"]*)" field should not contain "([^\"]*)"$/ do |field_id, value|
  field_with_id(field_id).value.should_not =~ /#{value}/
end

Then /^"([^"]*)" should be selected for "([^"]*)"$/ do |value, field_id|
  field_with_id(field_id).element.search(".//option[@selected = 'selected']").inner_html.should =~ /#{value}/
end

Then /^the "([^\"]*)" ([^ ]+) not include incorret member values$/ do |object_name, class_name|
  object = eval(class_name.capitalize).send("find", :first, :attribute => 'displayName', :value => object_name)
  members_method = class_name == "school" ? "user_members" : "members"
  object.send(members_method).each do |m|
    lambda{ User.find(m.puavoId) }.should_not raise_error
  end
end

When /^I follow "([^\"]*)" on the "([^\"]*)" ([^ ]+)$/ do |link_name, name, model|
  link_id = link_name.downcase + "_#{model}_" + 
    eval(model.capitalize).send("find", :first,
                                :attribute => "displayName",
                                :value => name ).id.to_s
  steps %Q{
    When I follow "#{link_id}"
  }
end

Then /^the id "([^\"]*)" checkbox should be checked$/ do |id|
  field_with_id(id).should be_checked
end
