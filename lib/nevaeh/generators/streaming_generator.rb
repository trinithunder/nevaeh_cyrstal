module Nevaeh
  module Generators
    class StreamingGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)
      
      def install
        say "Step 1: Generate models for Streaming and Video", :green
        create_video_model
        say "Step 2: Define methods related to video streaming", :green
        create_video_methods
        say "Step 3: Create Streaming model to handle streaming sessions or services", :green
        create_streaming_model
        say "Step 4: Define methods related to streaming sessions or services", :green
        create_streaming_methods
        say "Step 5: Add ActionText to Video for metadata", :green
        add_action_text_to_video
      end

      private
      # Step 1: Generate models for Streaming and Video
      def create_video_model
        generate "model", "Video title:string description:text streaming_url:string"
        generate "action_text:install"
        generate "migration AddMetadataToVideos metadata:text"
      end

      # Step 2: Define methods related to video streaming
      def create_video_methods
        inject_into_class "app/models/video.rb", "Video" do
          <<-RUBY
            has_rich_text :metadata  # ActionText for storing metadata
            
            validates :title, presence: true
            validates :streaming_url, presence: true

            # Method to fetch streaming URL
            def streaming_url
              # Placeholder logic, replace with actual URL logic
              super
            end

            # Custom method for pre-defining commands or code when creating video objects
            def predefined_commands
              {
                encode_video: "ffmpeg -i video.mp4 -vcodec libx264 -acodec aac -strict -2 output.mp4",
                stream_video: "streaming_tool --url #{streaming_url} --title #{title}"
              }
            end
          RUBY
        end
      end

      # Step 3: Create Streaming model to handle streaming sessions or services
      def create_streaming_model
        generate "model", "Streaming service_name:string video:references started_at:datetime ended_at:datetime"
      end

      # Step 4: Define methods related to streaming sessions or services
      def create_streaming_methods
        inject_into_class "app/models/streaming.rb", "Streaming" do
          <<-RUBY
            belongs_to :video

            # Placeholder logic for a streaming session
            def active?
              # Add logic to check if streaming session is active
              started_at <= Time.current && ended_at.nil?
            end

            def stop_streaming
              # Placeholder logic to end a streaming session
              update(ended_at: Time.current)
            end
          RUBY
        end
      end

      # Step 5: Add ActionText to Video for metadata
      def add_action_text_to_video
        inject_into_class "app/models/video.rb", "Video" do
          "  has_rich_text :metadata\n"
        end
      end
    end
  end
end
