class UploadsController < ApplicationController
  def index
		@uploads = Upload.all
  end

  def show
		@upload = Upload.find(params[:id])
  end

  def new 
		@upload = Upload.new
  end

  def create 
    @upload = Upload.new(upload_params)
    if @upload.save
      redirect_to root_path
    else
      render :new
    end
  end

  def destroy
    @upload = Upload.find(params[:id])
    @upload.destroy

    redirect_to root_path
  end

  private
    def upload_params
      params.require(:upload).permit(:title, :body)
    end
end
