# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :authenticate_user!, only: [ :edit, :update ]
  before_action :set_user

  # GET /users/:id
  def show
    render json: @user
  end

  # GET /users/:id/edit
  def edit
    authorize! :edit, @user
    render json: @user
  end

  # PATCH /users/:id
  def update
    authorize! :update, @user

    if @user.update(user_params)
      render json: @user, status: :ok
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
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
