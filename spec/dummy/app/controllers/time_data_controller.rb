class TimeDataController < ApplicationController
  before_action :set_time_datum, only: [:show, :edit, :update, :destroy]

  # GET /time_data
  def index
    @time_data = TimeDatum.all
  end

  # GET /time_data/1
  def show
  end

  # GET /time_data/new
  def new
    @time_datum = TimeDatum.new
  end

  # GET /time_data/1/edit
  def edit
  end

  # POST /time_data
  def create
    @time_datum = TimeDatum.new(time_datum_params)

    if @time_datum.save
      redirect_to @time_datum, notice: 'Time datum was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /time_data/1
  def update
    if @time_datum.update(time_datum_params)
      redirect_to @time_datum, notice: 'Time datum was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /time_data/1
  def destroy
    @time_datum.destroy
    redirect_to time_data_url, notice: 'Time datum was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_time_datum
      @time_datum = TimeDatum.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def time_datum_params
      params.require(:time_datum).permit(:subject, :time_value, :timestamp_value)
    end
end
