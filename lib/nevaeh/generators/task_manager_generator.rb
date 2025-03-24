# lib/generators/nevaeh_crystal/task_manager_generator.rb
module Nevaeh
  
  module Generators
    class TaskManagerGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      # The main method that runs when the generator is invoked
      def create_task_manager_files
        create_service_file('signal_service.rb', 'SignalService', 'transmit_signal')
        create_service_file('data_service.rb', 'DataService', 'store_or_retrieve')
        create_service_file('analysis_service.rb', 'AnalysisService', 'analyze_and_conclude')
        create_service_file('response_service.rb', 'ResponseService', 'immediate_response')
        create_service_file('background_processing_service.rb', 'BackgroundProcessingService', 'process_background_task')
        create_service_file('idea_generation_service.rb', 'IdeaGenerationService', 'generate_new_idea')
        create_service_file('astrology_service.rb', 'AstrologyService', 'apply_astrological_influence')

        create_task_manager_file
        create_initializer_file
      end

      private

      # Helper method to create a service file
      def create_service_file(file_name, service_name, method_name)
        template "services/#{file_name}.erb", "app/services/nevaeh_crystal/#{file_name}"
        inject_service_method(service_name, method_name)
      end

      # Helper method to inject the method implementation into the service class
      def inject_service_method(service_name, method_name)
        gsub_file("app/services/nevaeh_crystal/#{service_name.underscore}.rb", /# METHOD_IMPLEMENTATION/, "def #{method_name}(data)\n    puts 'Performing #{method_name} for #{service_name}'\n    # Add actual logic here\nend")
      end

      # Helper method to create the TaskManager file
      def create_task_manager_file
        template 'task_manager.rb.erb', 'app/services/nevaeh_crystal/task_manager.rb'
      end

      # Helper method to create the initializer file
      def create_initializer_file
        template 'initializer.rb.erb', 'config/initializers/nevaeh_crystal.rb'
      end
    end
  end
  
end
