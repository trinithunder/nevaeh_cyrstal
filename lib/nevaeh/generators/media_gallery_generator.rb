# Running the Generator:
#
# To run this generator, you would use: rails g nevaeh:media_gallery

module Nevaeh
  module Generators
    class MediaGalleryGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      def generate_gallery
        create_gallery_model
        create_gallery_controller
        create_gallery_views
        add_routes
        create_gallery_component
      end

      private

      # Creates a MediaGallery model to store images/videos
      def create_gallery_model
        generate "model", "MediaGallery user:references title:string description:text media:json"
        rake "db:migrate"
      end

      # Creates a controller to manage galleries
      def create_gallery_controller
        create_file "app/controllers/media_galleries_controller.rb", <<-FILE
          class MediaGalleriesController < ApplicationController
            before_action :set_media_gallery, only: [:show, :edit, :update, :destroy]

            def index
              @media_galleries = current_user.media_galleries
            end

            def show
            end

            def new
              @media_gallery = current_user.media_galleries.new
            end

            def create
              @media_gallery = current_user.media_galleries.new(media_gallery_params)
              if @media_gallery.save
                redirect_to @media_gallery, notice: 'Media gallery was successfully created.'
              else
                render :new
              end
            end

            def edit
            end

            def update
              if @media_gallery.update(media_gallery_params)
                redirect_to @media_gallery, notice: 'Media gallery was successfully updated.'
              else
                render :edit
              end
            end

            def destroy
              @media_gallery.destroy
              redirect_to media_galleries_url, notice: 'Media gallery was successfully destroyed.'
            end

            private
              def set_media_gallery
                @media_gallery = current_user.media_galleries.find(params[:id])
              end

              def media_gallery_params
                params.require(:media_gallery).permit(:title, :description, media: [])
              end
          end
        FILE
      end

      # Creates views for gallery management
      def create_gallery_views
        create_file "app/views/media_galleries/index.html.erb", <<-FILE
          <h1>Your Media Galleries</h1>
          <%= link_to 'New Media Gallery', new_media_gallery_path %>
          <ul>
            <% @media_galleries.each do |gallery| %>
              <li>
                <%= link_to gallery.title, gallery_path(gallery) %>
                <%= link_to 'Edit', edit_media_gallery_path(gallery) %> |
                <%= link_to 'Delete', media_gallery_path(gallery), method: :delete, data: { confirm: 'Are you sure?' } %>
              </li>
            <% end %>
          </ul>
        FILE

        create_file "app/views/media_galleries/show.html.erb", <<-FILE
          <h1><%= @media_gallery.title %></h1>
          <p><%= @media_gallery.description %></p>
          <div class="gallery-media">
            <% @media_gallery.media.each do |media_item| %>
              <%= image_tag media_item, class: "media-item" %>
            <% end %>
          </div>
          <%= link_to 'Edit', edit_media_gallery_path(@media_gallery) %> |
          <%= link_to 'Back', media_galleries_path %>
        FILE

        create_file "app/views/media_galleries/new.html.erb", <<-FILE
          <h1>New Media Gallery</h1>
          <%= form_with model: @media_gallery, local: true do |form| %>
            <div>
              <%= form.label :title %>
              <%= form.text_field :title %>
            </div>

            <div>
              <%= form.label :description %>
              <%= form.text_area :description %>
            </div>

            <div>
              <%= form.label :media %>
              <%= form.file_field :media, multiple: true %>
            </div>

            <%= form.submit %>
          <% end %>
        FILE
      end

      # Adds routes for media galleries
      def add_routes
        route "resources :media_galleries"
      end

      # Creates a component that can be added to a user's profile
      def create_gallery_component
        create_file "app/models/user_component.rb", <<-FILE
          class UserComponent < ApplicationRecord
            belongs_to :user
            has_rich_text :content

            def render_html
              content.body.to_s.gsub(/<media-gallery user_id=\"(\d+)\"\/>/) do
                user = User.find_by(id: $1)
                if user && user.allowed_component?('media_gallery')
                  ApplicationController.render(partial: 'users/media_gallery', locals: { user: user })
                else
                  ''
                end
              end
            end

            def render_json
              { content: render_html }.to_json
            end
          end
        FILE
      end
    end
  end
end
