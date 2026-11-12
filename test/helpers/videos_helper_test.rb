# Copilot-authored: Begin YouTube URL helper tests.
require "test_helper"

class VideosHelperTest < ActionView::TestCase
  test "accepts valid YouTube links" do
    assert_equal "https://www.youtube.com/watch?v=abcdefghijk",
      youtube_video_url("https://www.youtube.com/watch?v=abcdefghijk")
  end

  test "does not accept URLs from other hosts" do
    assert_nil youtube_video_url("https://youtube.com.attacker.example/watch?v=abcdefghijk")
    assert_nil youtube_video_url("javascript:alert(1)")
  end
end
# Copilot-authored: End YouTube URL helper tests.
