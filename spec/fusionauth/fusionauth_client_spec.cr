require "../spec_helper"
require "uuid"

describe FusionAuth::FusionAuthClient do
  it "should test application crud" do
    id = UUID.random.to_s
    client = FusionAuth::FusionAuthClient.new(ENV["FUSIONAUTH_API_KEY"], ENV["FUSIONAUTH_URL"])
    response = client.create_application(id, {
      "application" => {
        "name"  => "Test application",
        "roles" => [
          {
            "isDefault"   => false,
            "name"        => "admin",
            "isSuperRole" => true,
            "description" => "Admin role",
          },
          {
            "isDefault"   => true,
            "name"        => "user",
            "description" => "User role",
          },
        ],
      },
    })
    response.should be_successful
    response.success_response.not_nil!["application"]["name"].as_s.should eq("Test application")
    response.success_response.not_nil!["application"]["roles"][0]["name"].as_s.should eq("admin")
    response.success_response.not_nil!["application"]["roles"][1]["name"].as_s.should eq("user")

    # Create a new role
    response = client.create_application_role(id, nil, {
      "role" => {
        "isDefault"   => true,
        "name"        => "new role",
        "description" => "New role description",
      },
    })
    response.should be_successful
    application_role = response.success_response.not_nil!
    response = client.retrieve_application(id)
    response.should be_successful
    response.success_response.not_nil!["application"]["roles"][0]["name"].as_s.should eq("admin")
    response.success_response.not_nil!["application"]["roles"][1]["name"].as_s.should eq("new role")
    response.success_response.not_nil!["application"]["roles"][2]["name"].as_s.should eq("user")

    # Update the role
    response = client.update_application_role(id, application_role["role"]["id"].as_s, {
      "role" => {
        "isDefault"   => false,
        "name"        => "new role",
        "description" => "New role description",
      },
    })
    response.should be_successful
    response = client.retrieve_application(id)
    response.should be_successful
    response.success_response.not_nil!["application"]["roles"][1]["isDefault"].as_bool.should be_false

    # Delete the role
    client.delete_application_role(id, application_role["role"]["id"].as_s)
    response.should be_successful
    response = client.retrieve_application(id)
    response.should be_successful
    response.success_response.not_nil!["application"]["roles"][0]["name"].as_s.should eq("admin")
    response.success_response.not_nil!["application"]["roles"][1]["name"].as_s.should eq("user")

    # Deactivate the application
    response = client.deactivate_application(id)
    response.should be_successful
    response.success_response.should be_nil
    response = client.retrieve_application(id)
    response.should be_successful
    response.success_response.not_nil!["application"]["active"].as_bool.should be_false

    # Reactivate the application
    response = client.reactivate_application(id)
    response.should be_successful
    response.success_response.not_nil!["application"]["active"].as_bool.should be_true
    response = client.retrieve_application(id)
    response.should be_successful
    response.success_response.not_nil!["application"]["active"].as_bool.should be_true

    # Hard delete the application
    response = client.delete_application(id)
    response.should be_successful
    response.success_response.should be_nil
    response = client.retrieve_application(id)
    response.success_response.should be_nil
    response.status.should eq(404)
  end

  it "should test email template crud" do
    id = UUID.random.to_s
    client = FusionAuth::FusionAuthClient.new(ENV["FUSIONAUTH_API_KEY"], ENV["FUSIONAUTH_URL"])

    # Create the email template
    response = client.create_email_template(id, {
      "emailTemplate" => {
        "defaultFromName"     => "Dude",
        "defaultHtmlTemplate" => "HTML Template",
        "defaultSubject"      => "Subject",
        "defaultTextTemplate" => "Text Template",
        "fromEmail"           => "from@fusionauth.io",
        "localizedFromNames"  => {
          "fr" => "From fr",
        },
        "name" => "Test Template",
      },
    })
    response.should be_successful

    # Retrieve the email template
    response = client.retrieve_email_template(id)
    response.should be_successful
    response.success_response.not_nil!["emailTemplate"]["name"].as_s.should eq("Test Template")

    # Update the email template
    response = client.update_email_template(id, {
      "emailTemplate" => {
        "defaultFromName"     => "Dude",
        "defaultHtmlTemplate" => "HTML Template",
        "defaultSubject"      => "Subject",
        "defaultTextTemplate" => "Text Template",
        "fromEmail"           => "from@fusionauth.io",
        "localizedFromNames"  => {
          "fr" => "From fr",
        },
        "name" => "Test Template updated",
      },
    })
    response.should be_successful
    response = client.retrieve_email_template(id)
    response.should be_successful
    response.success_response.not_nil!["emailTemplate"]["name"].as_s.should eq("Test Template updated")

    # Preview it
    response = client.retrieve_email_template_preview({
      "emailTemplate" => {
        "defaultFromName"     => "Dude",
        "defaultHtmlTemplate" => "HTML Template",
        "defaultSubject"      => "Subject",
        "defaultTextTemplate" => "Text Template",
        "fromEmail"           => "from@fusionauth.io",
        "localizedFromNames"  => {
          "fr" => "From fr",
        },
        "name" => "Test Template updated",
      },
      "locale" => "fr",
    })
    response.should be_successful
    response.success_response.not_nil!["email"]["from"]["display"].as_s.should eq("From fr")

    # Delete the email template
    response = client.delete_email_template(id)
    response.success_response.should be_nil
    response = client.retrieve_email_template(id)
    response.status.should eq(404)
  end

  # TODO: fix updating user
  it "should test user crud" do
    id = UUID.random.to_s
    client = FusionAuth::FusionAuthClient.new(ENV["FUSIONAUTH_API_KEY"], ENV["FUSIONAUTH_URL"])

    # Create a user
    response = client.create_user(id, {
      "user" => {
        "firstName" => "Crystal",
        "lastName"  => "Client",
        "email"     => "crystal.client.test@fusionauth.io",
        "password"  => "password",
      },
    })
    response.should be_successful

    # Retrieve the user
    response = client.retrieve_user(id)
    response.should be_successful
    response.success_response.not_nil!["user"]["email"].as_s.should eq("crystal.client.test@fusionauth.io")

    # Update the user
    response = client.update_user(id, {
      "user" => {
        "firstName" => "Crystal updated",
        "lastName"  => "Client updated",
        "email"     => "crystal.client.test+updated@fusionauth.io",
        # "password"  => "password updated",
      },
    })
    response.should be_successful
    response.success_response.not_nil!["user"]["email"].as_s.should eq("crystal.client.test+updated@fusionauth.io")
    response = client.retrieve_user(id)
    response.should be_successful
    response.success_response.not_nil!["user"]["email"].as_s.should eq("crystal.client.test+updated@fusionauth.io")

    # Delete the user
    response = client.delete_user(id)
    response.should be_successful
    response.success_response.should be_nil
    response = client.retrieve_user(id)
    response.status.should eq(404)
  end

  it "should test user registration crud and login" do
    id = UUID.random.to_s
    application_id = UUID.random.to_s
    client = FusionAuth::FusionAuthClient.new(ENV["FUSIONAUTH_API_KEY"], ENV["FUSIONAUTH_URL"])

    # Create and application
    response = client.create_application(application_id, {
      "application" => {
        "name"  => "Test application",
        "roles" => [
          {
            "isDefault"   => false,
            "name"        => "admin",
            "isSuperRole" => true,
            "description" => "Admin role",
          },
          {
            "isDefault"   => true,
            "name"        => "user",
            "description" => "User role",
          },
        ],
      },
    })
    response.should be_successful

    # Create a user + registration
    response = client.register(id, {
      "user" => {
        "firstName" => "Crystal",
        "lastName"  => "Client",
        "email"     => "crystal.client.test@fusionauth.io",
        "password"  => "password",
      },
      "registration" => {
        "applicationId" => application_id,
        "data"          => {
          "foo" => "bar",
        },
        "preferredLanguages" => %w(en fr),
        "roles"              => %w(user),
      },
    })
    response.should be_successful

    # Authenticate the user
    response = client.login({
      "loginId"       => "crystal.client.test@fusionauth.io",
      "password"      => "password",
      "applicationId" => application_id,
    })
    response.should be_successful
    response.success_response.not_nil!["user"]["email"].as_s.should eq("crystal.client.test@fusionauth.io")

    # Retrieve the registration
    response = client.retrieve_registration(id, application_id)
    response.should be_successful
    response.success_response.not_nil!["registration"]["roles"][0].as_s.should eq("user")
    response.success_response.not_nil!["registration"]["data"]["foo"].as_s.should eq("bar")

    # Update the registration
    response = client.update_registration(id, {
      "registration" => {
        "applicationId" => application_id,
        "data"          => {
          "foo" => "bar updated",
        },
        "preferredLanguages" => %w(en fr),
        "roles"              => %w(admin),
      },
    })
    response.should be_successful
    response.success_response.not_nil!["registration"]["roles"][0].as_s.should eq("admin")
    response.success_response.not_nil!["registration"]["data"]["foo"].as_s.should eq("bar updated")
    response = client.retrieve_registration(id, application_id)
    response.should be_successful
    response.success_response.not_nil!["registration"]["roles"][0].as_s.should eq("admin")
    response.success_response.not_nil!["registration"]["data"]["foo"].as_s.should eq("bar updated")

    # Delete the registration
    response = client.delete_registration(id, application_id)
    response.success_response.should be_nil
    response = client.retrieve_registration(id, application_id)
    response.status.should eq(404)

    # Delete the application & user as clean-up
    client.delete_application(application_id)
    client.delete_user(id)
  end
end
