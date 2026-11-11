require 'test_helper'

class VideosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @video = videos(:one)
  end

  test "should get index" do
    get videos_url
    assert_response :success
    # Copilot-authored: Verify the bulk-delete action is available from the navigation.
    assert_select 'a[data-method="delete"][href=?]', delete_watched_videos_path
    # End Copilot-authored section.
  end

  test "should get new" do
    get new_video_url
    assert_response :success
  end

  test "should create video" do
    assert_difference('Video.count') do
      post videos_url, params: { video: { channel: @video.channel, subscription: @video.subscription, title: @video.title, url: @video.url, watched: @video.watched } }
    end

    assert_redirected_to video_url(Video.last)
  end

  test "should show video" do
    get video_url(@video)
    assert_response :success
  end

  test "should get edit" do
    get edit_video_url(@video)
    assert_response :success
  end

  test "should update video" do
    patch video_url(@video), params: { video: { channel: @video.channel, subscription: @video.subscription, title: @video.title, url: @video.url, watched: @video.watched } }
    assert_redirected_to video_url(@video)
  end

  test "should destroy video" do
    assert_difference('Video.count', -1) do
      delete video_url(@video)
    end

    assert_redirected_to videos_url
  end

  # Copilot-authored: Verify the bulk action removes only watched records and reports both counts.
  test "should delete watched videos and report remaining count" do
    watched_video = videos(:one)
    watched_video.update!(watched: true)

    assert_difference('Video.count', -1) do
      delete delete_watched_videos_url
    end

    assert_redirected_to videos_url
    assert_equal 'Deleted 1 watched videos; 1 videos remain.', flash[:notice]
    assert_not Video.exists?(watched_video.id)
    assert Video.where(watched: false).exists?
  end
  # End Copilot-authored section.
end
