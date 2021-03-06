Given /^the following schools:$/ do |schools|
  schools = School.create!(schools.hashes)
end

When /^I delete the (\d+)(?:st|nd|rd|th) school$/ do |pos|
  visit schools_url
  within("table > tr:nth-child(#{pos.to_i+1})") do
    click_link "Destroy"
  end
end

Then /^I should see the following schools:$/ do |expected_schools_table|
  expected_schools_table.diff!(table_at('table').to_a)
end

When /^I fill test data into school forms$/ do
  default_form_value.each do |field, value|
    fill_in(field, :with => value)
  end
end

When /^I fill modify test data into school forms$/ do
  default_form_value.each do |field, value|
    fill_in(field, :with => value + " modify")
  end
end

Then /^I should see same test data on the page$/ do
  default_form_value.each do |field, value|
    response.should contain(value)
  end
end

Then /^I should see same modify test data on the page$/ do
  default_form_value.each do |field, value|
    response.should contain(value + " modify")
  end
end

Then /^I should see same test data on the forms$/ do
  default_form_value.each do |field, value|
    field_named(field).value.should =~ /#{value}/
  end
end

def default_form_value
  { "school[name]" => "Halssila School",
    "school[home_page]" => "http://www.halssila.com",
    "school[description]" => "Some description text",
    "school[phone_number]" => "\\+3581412126789",
    "school[fax_number]" => "\\+3581412666689",
    "school[primary_contact_email]" => "test@some.com",
    #"school[tags]" => "schooltag", FIXME
    "postal_address[name]" => "Some postal address name",
    "postal_address[street_address]" => "Some address 45",
    "postal_address[zip_code]" => "12345",
    "postal_address[city]" => "Jyväskylä",
    "postal_address[state]" => "Lansi-Suomen laani",
    "postal_address[email]" => "some@some.com",
    "delivery_address[name]" => "Some delivery address name",
    "delivery_address[street_address]" => "Some address 55",
    "delivery_address[zip_code]" => "54321",
    "delivery_address[city]" => "Some city",
    "delivery_address[state]" => "Some state",
    "delivery_address[email]" => "test@some.com",
    "billing_address[name]" => "Some billing address name",
    "billing_address[street_address]" => "Some address 66",
    "billing_address[zip_code]" => "98765",
    "billing_address[city]" => "London",
    "billing_address[state]" => "test state",
    "billing_address[email]" => "london@test.uk" }
end

Then /^the ([^ ]*) should include "([^\"]*)" on the "([^\"]*)" school$/ do |attribute, uid, school_name|
  school_member_include?(attribute, school_name, uid).should be_true
end

Then /^the ([^ ]*) should not include "([^\"]*)" on the "([^\"]*)" school$/ do |attribute, uid, school_name|
  school = School.find( :first, :attribute => "displayName", :value => school_name )
  if attribute == "memberUid"
    school.memberUid.include?(uid).should be_false
  else
    user = User.find( :first, :attribute => "uid", :value => uid )
    school.send(attribute).include?(user).should be_false
  end
end

def school_member_include?(attribute, school_name, uid)
  school = School.find( :first, :attribute => "displayName", :value => school_name )
  user = User.find( :first, :attribute => "uid", :value => uid )
  return school.send(attribute).include?(user)
end
