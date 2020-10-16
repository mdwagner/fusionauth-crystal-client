require "spec"
require "webmock"
require "../src/fusionauth"

Spec.before_each &->WebMock.reset
