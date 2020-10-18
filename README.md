# FusionAuth::FusionAuthClient

This shard is the Crystal client library that helps connect Crystal applications to the FusionAuth (https://fusionauth.io) Identity and User Management platform.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  fusionauth_client:
    github: FusionAuth/fusionauth-crystal-client
```

## Usage

Once the shard is installed, you can call FusionAuth APIs like this:

```crystal
require "uuid"
require "fusionauth_client/fusionauth"

# Construct the FusionAuth Client
client = FusionAuth::FusionAuthClient.new(
  "<YOUR_API_KEY>",
  "<YOUR_FUSIONAUTH_URL>"
)
application_id = "<YOUR_APP_ID>"

# Create a user + registration
id = UUID.random.to_s
client.register(id, {
  "user" => {
    "firstName" => "Crystal",
    "lastName" => "Client",
    "email" => "crystal.client.test@fusionauth.io",
    "password" => "password",
  },
  "registration" => {
    "applicationId" => application_id,
    "data" => {
      "foo" => "bar",
    },
    "preferredLanguages" => %w(en fr),
    "roles" => %w(user),
  }
})

# Authenticate the user
response = client.login({
  "loginId" => "crystal.client.test@fusionauth.io",
  "password" => "password",
  "applicationId" => application_id,
})
user = response.success_response.not_nil!["user"]
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/FusionAuth/fusionauth-crystal-client. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The shard is available as open source under the terms of the [Apache v2.0 License](https://opensource.org/licenses/Apache-2.0).
