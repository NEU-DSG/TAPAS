# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!, only: [ :edit, :update ]
  before_action :set_user

  # GET /users/:id
  def show
    respond_to do |format|
      format.html
      format.json { render json: @user }
    end
  end

  # GET /users/:id/edit
  def edit
    authorize! :edit, @user
    respond_to do |format|
      format.html
      format.json { render json: @user }
    end
  end

  # PATCH /users/:id
  def update
    authorize! :update, @user

    if @user.update(user_params)
      respond_to do |format|
        format.html { redirect_to user_path(@user), notice: "Profile updated." }
        format.json { render json: @user, status: :ok }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :bio, :institution,
      image_file_attributes: [ :id, :title, :alt_text, :file, :image_url, :_destroy ])
  end
end
