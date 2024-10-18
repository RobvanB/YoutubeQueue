class YtqParamsController < ApplicationController
  before_action :set_ytq_param, only: [:show, :edit, :update, :destroy]

  # GET /ytq_params
  # GET /ytq_params.json
  def index
    @ytq_params = YtqParam.all
  end

  # GET /ytq_params/1
  # GET /ytq_params/1.json
  def show
  end

  # GET /ytq_params/new
  def new
    @ytq_param = YtqParam.new
  end

  # GET /ytq_params/1/edit
  def edit
  end

  # POST /ytq_params
  # POST /ytq_params.json
  def create
    @ytq_param = YtqParam.new(ytq_param_params)

    respond_to do |format|
      if @ytq_param.save
        format.html { redirect_to @ytq_param, notice: 'Ytq param was successfully created.' }
        format.json { render :show, status: :created, location: @ytq_param }
      else
        format.html { render :new }
        format.json { render json: @ytq_param.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ytq_params/1
  # PATCH/PUT /ytq_params/1.json
  def update
    respond_to do |format|
      if @ytq_param.update(ytq_param_params)
        format.html { redirect_to @ytq_param, notice: 'Ytq param was successfully updated.' }
        format.json { render :show, status: :ok, location: @ytq_param }
      else
        format.html { render :edit }
        format.json { render json: @ytq_param.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ytq_params/1
  # DELETE /ytq_params/1.json
  def destroy
    @ytq_param.destroy
    respond_to do |format|
      format.html { redirect_to ytq_params_url, notice: 'Ytq param was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ytq_param
      @ytq_param = YtqParam.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def ytq_param_params
      params.require(:ytq_param).permit(:last_date)
    end
end
