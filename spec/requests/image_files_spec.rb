# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ImageFiles", type: :request do
  let(:owner) { create(:user) }
  let(:other_user) { create(:user) }
  let(:project) { create(:project, depositor: owner) }
  let(:collection) { create(:collection, project: project, depositor: owner) }
  let(:core_file) { create(:core_file, depositor: owner, collections: [ collection ]) }
  let(:valid_params) { { image_file: { title: "Thumbnail", alt_text: "An image", image_url: "https://example.com/img.jpg" } } }

  shared_examples "requires authentication" do |method, path_helper|
    it "redirects to sign in" do
      send(method, send(path_helper), params: valid_params)
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "User avatar (POST /users/:user_id/image_file)" do
    context "when not signed in" do
      it "redirects to sign in" do
        post user_image_file_path(owner), params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "as the user themselves" do
      before { sign_in owner }

      it "creates the image file" do
        post user_image_file_path(owner), params: valid_params, as: :json
        expect(response).to have_http_status(:created)
      end

      it "replaces an existing image file" do
        owner.create_image_file!(title: "Old", image_url: "https://example.com/old.jpg", depositor: owner)
        expect {
          post user_image_file_path(owner), params: valid_params, as: :json
        }.not_to change(ImageFile, :count)
        expect(owner.reload.image_file.title).to eq("Thumbnail")
      end
    end

    context "as another user" do
      before { sign_in other_user }

      it "returns forbidden" do
        post user_image_file_path(owner), params: valid_params, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "User avatar (DELETE /users/:user_id/image_file)" do
    before { owner.create_image_file!(title: "Avatar", image_url: "https://example.com/img.jpg", depositor: owner) }

    context "as the user themselves" do
      before { sign_in owner }

      it "destroys the image file" do
        expect {
          delete user_image_file_path(owner), as: :json
        }.to change(ImageFile, :count).by(-1)
      end

      it "returns no content" do
        delete user_image_file_path(owner), as: :json
        expect(response).to have_http_status(:no_content)
      end
    end

    context "as another user" do
      before { sign_in other_user }

      it "returns forbidden" do
        delete user_image_file_path(owner), as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "Project thumbnail (POST /projects/:project_id/image_file)" do
    context "as the project owner" do
      before { sign_in owner }

      it "creates the image file" do
        post project_image_file_path(project), params: valid_params, as: :json
        expect(response).to have_http_status(:created)
      end
    end

    context "as a non-owner" do
      before do
        create(:project_member, project: project, user: other_user, role: "contributor")
        sign_in other_user
      end

      it "returns forbidden" do
        post project_image_file_path(project), params: valid_params, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "as a non-member" do
      before { sign_in other_user }

      it "returns forbidden" do
        post project_image_file_path(project), params: valid_params, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "Collection thumbnail (POST /collections/:collection_id/image_file)" do
    context "as the collection depositor" do
      before { sign_in owner }

      it "creates the image file" do
        post collection_image_file_path(collection), params: valid_params, as: :json
        expect(response).to have_http_status(:created)
      end
    end

    context "as a non-member" do
      before { sign_in other_user }

      it "returns forbidden" do
        post collection_image_file_path(collection), params: valid_params, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "CoreFile thumbnail (POST /core_files/:core_file_id/image_file)" do
    before { core_file }

    context "as the core file depositor" do
      before { sign_in owner }

      it "creates the image file" do
        post core_file_image_file_path(core_file), params: valid_params, as: :json
        expect(response).to have_http_status(:created)
      end
    end

    context "as a non-member" do
      before { sign_in other_user }

      it "returns forbidden" do
        post core_file_image_file_path(core_file), params: valid_params, as: :json
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
