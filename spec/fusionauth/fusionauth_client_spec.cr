require "../spec_helper"

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
end
