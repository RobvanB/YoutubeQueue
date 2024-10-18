json.extract! video, :id, :title, :url, :subscription, :channel, :watched, :created_at, :updated_at
json.url video_url(video, format: :json)
