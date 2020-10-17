require "../spec_helper"
require "uuid"

describe FusionAuth::FusionAuthClient do
  it "should test application crud" do
    id = UUID.random.to_s
    client = FusionAuth::FusionAuthClient.new(ENV["FUSIONAUTH_API_KEY"], ENV["FUSIONAUTH_URL"])
    response = client.create_application(id, {
      "application" => {
        "name" => "Test application",
        "roles" => [
          {
            "isDefault" => false,
            "name" => "admin",
            "isSuperRole" => true,
            "description" => "Admin role",
          },
          {
            "isDefault" => true,
            "name" => "user",
            "description" => "User role",
          },
        ],
      }
    })
    response.was_successful.should be_true
    response.success_response.not_nil!["application"]["name"].as_s.should eq("Test application")
    response.success_response.not_nil!["application"]["roles"][0]["name"].as_s.should eq("admin")
    response.success_response.not_nil!["application"]["roles"][1]["name"].as_s.should eq("user")

    # Create a new role
    response = client.create_application_role(id, nil, {
      "role" => {
        "isDefault" => true,
        "name" => "new role",
        "description" => "New role description",
      },
    })
    response.was_successful.should be_true
    application_role = response.success_response.not_nil!
    response = client.retrieve_application(id)
    response.was_successful.should be_true
    response.success_response.not_nil!["application"]["roles"][0]["name"].as_s.should eq("admin")
    response.success_response.not_nil!["application"]["roles"][1]["name"].as_s.should eq("new role")
    response.success_response.not_nil!["application"]["roles"][2]["name"].as_s.should eq("user")

    # Update the role
    response = client.update_application_role(id, application_role["role"]["id"].as_s, {
      "role" => {
        "isDefault" => false,
        "name" => "new role",
        "description" => "New role description",
      },
    })
    response.was_successful.should be_true
    response = client.retrieve_application(id)
    response.was_successful.should be_true
    response.success_response.not_nil!["application"]["roles"][1]["isDefault"].as_bool.should be_false

    # Delete the role
    client.delete_application_role(id, application_role["role"]["id"].as_s)
    response.was_successful.should be_true
    response = client.retrieve_application(id)
    response.was_successful.should be_true
    response.success_response.not_nil!["application"]["roles"][0]["name"].as_s.should eq("admin")
    response.success_response.not_nil!["application"]["roles"][1]["name"].as_s.should eq("user")

    # Deactivate the application
    response = client.deactivate_application(id)
    response.was_successful.should be_true
    response.success_response.should be_nil
    response = client.retrieve_application(id)
    response.was_successful.should be_true
    response.success_response.not_nil!["application"]["active"].as_bool.should be_false

    # Reactivate the application
    response = client.reactivate_application(id)
    response.was_successful.should be_true
    response.success_response.not_nil!["application"]["active"].as_bool.should be_true
    response = client.retrieve_application(id)
    response.was_successful.should be_true
    response.success_response.not_nil!["application"]["active"].as_bool.should be_true

    # Hard delete the application
    response = client.delete_application(id)
    response.was_successful.should be_true
    response.success_response.should be_nil
    response = client.retrieve_application(id)
    response.success_response.should be_nil
    response.status.should eq(404)
  end
end
