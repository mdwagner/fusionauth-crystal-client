module CustomExpectations
  struct BeSuccessfulExpectation
    def match(actual_value)
      response = actual_value
      response.was_successful
    end

    def failure_message(actual_value)
      response = actual_value
      "Expected: response should be successful\nActual:\n  status(#{response.status})\n  error_response(#{response.error_response.try(&.to_json)})\n  exception_message(#{response.exception.try(&.message)})"
    end

    def negative_failure_message(actual_value)
      response = actual_value
      "Expected: response should be unsuccessful\nActual:\n  status(#{response.status})\n  success_response(#{response.success_response.try(&.to_json)})\n  exception_message(#{response.exception.try(&.message)})"
    end
  end

  def be_successful
    BeSuccessfulExpectation.new
  end
end
