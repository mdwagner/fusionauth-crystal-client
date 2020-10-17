require "../spec_helper"
require "uuid"
require "log"

describe FusionAuth::FusionAuthClient do
  it "should retrieve email templates" do
    WebMock.stub(:any, /localhost:9011/)
      .to_return(
        status: 200,
        headers: HTTP::Headers{"content-type" => "application/json"},
        body: {"abc" => "123"}.to_json
      )

    client = FusionAuth::FusionAuthClient.new("api_key", "http://localhost:9011")
    response = client.retrieve_email_templates

    response.status.should eq(200)
    response.success_response.should_not be_nil

    success_response = response.success_response.not_nil!
    success_response["abc"].as_s.should eq("123")
  end

  if ENV["FUSIONAUTH_API_KEY"]? && ENV["FUSIONAUTH_URL"]?
    it "should test application crud" do
      WebMock.allow_net_connect = true

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

      ex = response.exception.not_nil!
      Log.error(exception: ex) { "error" }

      response.was_successful.should be_true
      response.success_response.should_not be_nil

      success_response = response.success_response.not_nil!
      success_response["application"]["name"].as_s.should eq("Test application")
      success_response["application"]["roles"][0]["name"].as_s.should eq("admin")
      success_response["application"]["roles"][1]["name"].as_s.should eq("user")
    end
  end
end
