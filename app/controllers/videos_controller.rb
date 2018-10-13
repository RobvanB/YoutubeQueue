class VideosController < ApplicationController
  before_action :set_video, only: [:show, :edit, :update, :destroy]

  def pull
    # First check authentication
    response  = YoutubeQueue.new.authorize
    type      = response[:type]

    if type == 'url'
      url = response[:url]
    else
      credentials = response[:credentials]
    end

    if url.nil? || url.empty?
      # get new videos from Youtube
      counters = YoutubeQueue.new.get_videos(credentials)

      flash[:notice] = "Updated " + counters['vid_count'].to_s + " videos from " + 
                                  counters['sub_count'].to_s + " subscriptions."
     
      @videos = Video.all
    else
      # (re-)authenticate
      redirect_to url
    end
  end

  def set_token
    YoutubeQueue.new.do_set_token(params[:code])
    redirect_to videos_path
  end
  
  def get_subscriptions
    @my_scubscriptions = YoutubeQueue.new.get_subscriptions
  end

  # GET /videos
  # GET /videos.json
  def index
    @videos = Video.all
  end

  # GET /videos/1
  # GET /videos/1.json
  def show
  end

  # GET /videos/new
  def new
    @video = Video.new
  end

  # GET /videos/1/edit
  def edit
  end

  # POST /videos
  # POST /videos.json
  def create
    @video = Video.new(video_params)

    respond_to do |format|
      if @video.save
        format.html { redirect_to @video, notice: 'Video was successfully created.' }
        format.json { render :show, status: :created, location: @video }
      else
        format.html { render :new }
        format.json { render json: @video.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /videos/1
  # PATCH/PUT /videos/1.json
  def update
    respond_to do |format|
      if @video.update(video_params)
        format.html { redirect_to @video, notice: 'Video was successfully updated.' }
        format.json { render :show, status: :ok, location: @video }
      else
        format.html { render :edit }
        format.json { render json: @video.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /videos/1
  # DELETE /videos/1.json
  def destroy
    @video.destroy
    respond_to do |format|
      format.html { redirect_to videos_url, notice: 'Video was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

 #Method for sending data for the dhtmlXgrid control
 def data
  videos = Video.all
  render :json => { :total_count => videos.length,
                    :pos => 0,
                    :rows => videos.map do |video|
                    {
                      :id => video.id,
                      :data => [video.channel, video.published, video.title, "Watch^" + video.url, 
                                video.watched ? "Yes" : "No",
                                "Set watched^" +  "set_watched/"+ video.id.to_s + "^_self" ,
                                "Edit^" + edit_video_path(video) ]
                    }
                    end
                  }
  end

  # Method for setting a video as watched
  def set_watched
    video = Video.find(params[:id])
    video.watched = true
    video.save
    respond_to do |format|
      format.html { redirect_to videos_url, notice: 'Video set to "watched".' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_video
      @video = Video.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def video_params
      params.require(:video).permit(:title, :url, :subscription, :channel, :watched)
    end
end
