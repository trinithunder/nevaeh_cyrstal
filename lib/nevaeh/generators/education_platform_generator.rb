module Nevaeh
  module Generators
    class EducationPlatformGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def install_school
        create_models
        end
        private
      
      def create_models
        generate "nevaeh:scaffold_rich_text Course --fields title:string"
        generate "nevaeh:scaffold_rich_text Lesson --fields title:string course:references"
        generate "nevaeh:scaffold_rich_text Enrollment --fields user:references course:references"
        generate "nevaeh:scaffold_rich_text Quiz --fields title:string course:references"
        generate "nevaeh:scaffold_rich_text Question --fields quiz:references"
        generate "nevaeh:scaffold_rich_text Answer --fields correct:boolean question:references"
        generate "nevaeh:scaffold_rich_text Test --fields title:string course:references"
        generate "nevaeh:scaffold_rich_text TestQuestion --fields test:references"
        generate "nevaeh:scaffold_rich_text TestAnswer --fields correct:boolean test_question:references"
        generate "nevaeh:scaffold_rich_text Grade --fields score:integer user:references course:references"
        generate "nevaeh:scaffold_rich_text CertificationProgram --fields name:string"
        generate "nevaeh:scaffold_rich_text DegreeProgram --fields name:string"
        generate "nevaeh:scaffold_rich_text Certificate --fields user:references course:references issued_at:datetime"
      end

      def create_controllers
        generate "controller", "Courses index show"
        generate "controller", "Lessons show"
        generate "controller", "Enrollments create"
        generate "controller", "Quizzes show submit"
        generate "controller", "Tests show submit"
        generate "controller", "Grades index"
        generate "controller", "CertificationPrograms index show"
        generate "controller", "DegreePrograms index show"
        generate "controller", "Certificates index show"
      end

      def create_views
        create_file "app/views/courses/index.html.erb", "<h1>All Courses</h1>"
        create_file "app/views/courses/show.html.erb", "<h1><%= @course.title %></h1>"
        create_file "app/views/lessons/show.html.erb", "<h1><%= @lesson.title %></h1>"
        create_file "app/views/quizzes/show.html.erb", "<h1>Quiz</h1>"
        create_file "app/views/tests/show.html.erb", "<h1>Test</h1>"
        create_file "app/views/grades/index.html.erb", "<h1>Grades</h1>"
        create_file "app/views/certification_programs/index.html.erb", "<h1>Certification Programs</h1>"
        create_file "app/views/certification_programs/show.html.erb", "<h1><%= @certification_program.name %></h1>"
        create_file "app/views/degree_programs/index.html.erb", "<h1>Degree Programs</h1>"
        create_file "app/views/degree_programs/show.html.erb", "<h1><%= @degree_program.name %></h1>"
        create_file "app/views/certificates/index.html.erb", "<h1>Certificates</h1>"
        create_file "app/views/certificates/show.html.erb", "<h1>Certificate for <%= @certificate.user.name %></h1>"
      end

      def update_routes
        route "resources :courses, only: [:index, :show] do\n  resources :lessons, only: [:show]\n  resources :enrollments, only: [:create]\n  resources :quizzes, only: [:show] do\n    post 'submit', on: :member\n  end\n  resources :tests, only: [:show] do\n    post 'submit', on: :member\n  end\n  resources :grades, only: [:index]\nend"
        route "resources :certification_programs, only: [:index, :show]"
        route "resources :degree_programs, only: [:index, :show]"
        route "resources :certificates, only: [:index, :show]"
      end

      def create_initializer
        create_file "config/initializers/education_platform.rb", "# Configuration for Education Platform"
      end
    end
  end
  
  
end