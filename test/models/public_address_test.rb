require "test_helper"

class PublicAddressTest < ActiveSupport::TestCase
  test "public addresses pass" do
    %w[ 8.8.8.8 69.164.205.165 2606:4700::1111 172.15.255.255 172.32.0.1 ].each do |address|
      assert PublicAddress.public?(address), address
    end
  end

  test "private, loopback, link-local, metadata and reserved addresses do not" do
    %w[ 10.0.0.1 172.16.0.1 172.31.255.255 192.168.1.1 127.0.0.1 169.254.169.254 100.64.0.1 0.0.0.0 224.0.0.1
        ::1 fe80::1 fc00::1 fd12:3456::1 ::ffff:10.0.0.1 ::ffff:127.0.0.1 not-an-ip ].each do |address|
      assert_not PublicAddress.public?(address), address
    end
    assert_not PublicAddress.public?(nil)
  end
end
