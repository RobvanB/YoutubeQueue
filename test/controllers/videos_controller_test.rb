require 'test_helper'

class VideosControllerTest < ActionDispatch::IntegrationTest
  setup do
    @video = videos(:one)
  end

  test "should get index" do
    get videos_url
    assert_response :success
    # Copilot-authored: Begin video library rendering assertions.
    assert_select '[data-video-library]'
    assert_select ".video-table tbody tr[data-video-card]", count: 2
    assert_select '[data-watched-filter] option[selected]', text: "No"
    assert_select 'a[href=?]', set_watched_path(@video)
    assert_select '[data-video-count="total"]', text: "2"
    assert_select '[data-video-count="unwatched"]', text: "2"
    assert_select '[data-video-count="watched"]', text: "0"
    assert_select '[data-video-count="subscriptions"]', text: "Not synced"
    # Copilot-authored: End video library rendering assertions.
    # Copilot-authored: Verify the bulk-delete action is available from the navigation.
    assert_select 'a[data-method="delete"][href=?]', delete_watched_videos_path
    # End Copilot-authored section.
  end

  # Copilot-authored: Begin video count tests.
  test "should show separate watched and unwatched counts" do
    videos(:one).update!(watched: true)

    get videos_url

    assert_response :success
    assert_select '[data-video-count="total"]', text: "2"
    assert_select '[data-video-count="unwatched"]', text: "1"
    assert_select '[data-video-count="watched"]', text: "1"
  end
  # Copilot-authored: End video count tests.

  # Copilot-authored: Begin unset watched status count test.
  test "counts videos with unset watched status as unwatched" do
    videos(:one).update!(watched: nil)
    videos(:two).update!(watched: nil)

    get videos_url

    assert_response :success
    assert_select '[data-video-count="total"]', text: "2"
    assert_select '[data-video-count="unwatched"]', text: "2"
    assert_select '[data-video-count="watched"]', text: "0"
  end
  # Copilot-authored: End unset watched status count test.

  # Copilot-authored: Begin subscription count session tests.
  test "pull stores the subscription count for subsequent page loads" do
    queue = Object.new
    queue.define_singleton_method(:authorize) { { credentials: :test } }
    queue.define_singleton_method(:get_videos) do |_credentials|
      {
        "vid_count" => 1,
        "found_count" => 1,
        "duplicate_count" => 0,
        "sub_count" => 7
      }
    end

    YoutubeQueue.define_singleton_method(:new) { queue }
    begin
      get pull_path
    ensure
      YoutubeQueue.singleton_class.send(:remove_method, :new)
    end

    assert_redirected_to videos_path
    follow_redirect!
    assert_select '[data-video-count="subscriptions"]', text: "7"
  end
  # Copilot-authored: End subscription count session tests.

  # Copilot-authored: Begin filter persistence and video ordering tests.
  test "should preserve channel and watched filters" do
    @video.update!(channel: "Example channel")

    post save_video_filter_url, params: { channel: "Example channel", watched: "watched" }
    assert_response :no_content

    get videos_url
    assert_select '[data-channel-filter] option[selected]', text: "Example channel"
    assert_select '[data-watched-filter] option[selected]', text: "Yes"
  end

  test "should list videos from oldest to newest" do
    videos(:one).update!(title: "Older video", published: Date.new(2020, 1, 1))
    videos(:two).update!(title: "Newer video", published: Date.new(2021, 1, 1))

    get videos_url

    assert_response :success
    assert_operator response.body.index("Older video"), :<, response.body.index("Newer video")
  end
  # Copilot-authored: End filter persistence and video ordering tests.

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
