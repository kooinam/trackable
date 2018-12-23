require 'test_helper'

class TrackableTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, Trackable
  end
end
