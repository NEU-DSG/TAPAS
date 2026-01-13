class CoreFilesController < ApplicationController
  def index
    @core_files = CoreFile.all
  end
end
