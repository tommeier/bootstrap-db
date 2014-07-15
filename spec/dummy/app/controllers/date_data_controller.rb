class DateDataController < ApplicationController
  before_action :set_date_datum, only: [:show, :edit, :update, :destroy]

  # GET /date_data
  def index
    @date_data = DateDatum.all
  end

  # GET /date_data/1
  def show
  end

  # GET /date_data/new
  def new
    @date_datum = DateDatum.new
  end

  # GET /date_data/1/edit
  def edit
  end

  # POST /date_data
  def create
    @date_datum = DateDatum.new(date_datum_params)

    if @date_datum.save
      redirect_to @date_datum, notice: 'Date datum was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /date_data/1
  def update
    if @date_datum.update(date_datum_params)
      redirect_to @date_datum, notice: 'Date datum was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /date_data/1
  def destroy
    @date_datum.destroy
    redirect_to date_data_url, notice: 'Date datum was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_date_datum
      @date_datum = DateDatum.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def date_datum_params
      params.require(:date_datum).permit(:subject, :date_value, :datetime_value)
    end
end
