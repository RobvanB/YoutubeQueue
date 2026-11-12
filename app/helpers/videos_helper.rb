# Copilot-authored: Begin safe YouTube video URL helpers.
require "uri"

module VideosHelper
  YOUTUBE_VIDEO_ID_PATTERN = /\A[A-Za-z0-9_-]{11}\z/
  YOUTUBE_HOSTS = %w[youtube.com www.youtube.com m.youtube.com youtu.be].freeze

  def youtube_video_id(video_url)
    return if video_url.blank?

    uri = URI.parse(video_url)
    return unless uri.scheme == "https" && uri.port == 443 && YOUTUBE_HOSTS.include?(uri.host&.downcase)

    video_id =
      if uri.host.downcase == "youtu.be"
        uri.path.split("/").reject(&:blank?).first
      elsif uri.path == "/watch"
        URI.decode_www_form(uri.query.to_s).to_h["v"]
      else
        uri.path.match(%r{\A/(?:embed|shorts)/([^/]+)})&.captures&.first
      end

    video_id if video_id&.match?(YOUTUBE_VIDEO_ID_PATTERN)
  rescue URI::InvalidURIError
    nil
  end

  def youtube_video_url(video_url)
    youtube_video_id(video_url) ? video_url : nil
  end

end
# Copilot-authored: End safe YouTube video URL helpers.
