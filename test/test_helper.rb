ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/stub_helper"
require_relative "test_helpers/local_server_helper"
require_relative "test_helpers/fakes"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    include StubHelper
  end
end
