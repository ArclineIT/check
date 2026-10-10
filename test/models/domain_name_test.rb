require "test_helper"

class DomainNameTest < ActiveSupport::TestCase
  test "accepts a hostname however it was pasted" do
    { "example.com" => "example.com", " Example.COM. " => "example.com", "https://www.example.com/path?q=1#top" => "www.example.com",
      "http://user:pass@example.com:8080/" => "example.com", "sub.domain.example.co.uk" => "sub.domain.example.co.uk",
      "xn--bcher-kva.example" => "xn--bcher-kva.example" }.each do |input, expected|
      assert_equal expected, DomainName.parse(input), input
    end
  end

  test "rejects anything that is not a public hostname" do
    [ "", "  ", "localhost", "example", "-bad.example.com", "bad-.example.com", "exa mple.com", "example..com",
      "127.0.0.1", "10.0.0.1", "[::1]", "example.com;rm -rf /", "a" * 64 + ".com", "<script>.com", nil ].each do |input|
      assert_raises(DomainName::Invalid, input.inspect) { DomainName.parse(input) }
    end
  end
end
