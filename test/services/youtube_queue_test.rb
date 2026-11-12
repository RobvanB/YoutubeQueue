# Copilot-authored: Begin subscription pagination tests.
require "minitest/autorun"
require "active_support/core_ext/object/blank"
require_relative "../../app/services/youtube_queue"

class YoutubeQueueTest < Minitest::Test
  SubscriptionPage = Struct.new(:items, :next_page_token)

  class SubscriptionServiceStub
    attr_reader :page_tokens

    def initialize(pages)
      @pages = pages
      @page_tokens = []
    end

    def list_subscriptions(_part, mine:, max_results:, page_token:)
      raise "Expected subscription lookup for the current user" unless mine
      raise "Expected a page size of 50" unless max_results == 50

      @page_tokens << page_token
      @pages.fetch(page_token)
    end
  end

  def test_get_subscriptions_fetches_every_page
    pages = {
      nil => SubscriptionPage.new([:first, :second], "page-2"),
      "page-2" => SubscriptionPage.new([:third], nil)
    }
    service = SubscriptionServiceStub.new(pages)
    queue = YoutubeQueue.allocate
    queue.instance_variable_set(:@service, service)

    assert_equal [:first, :second, :third], queue.get_subscriptions
    assert_equal [nil, "page-2"], service.page_tokens
  end
end
# Copilot-authored: End subscription pagination tests.
