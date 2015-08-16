require 'rails/generators/base'

module CanPlay
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __FILE__)

      desc "Creates a can_play initializer and copy locale files to your application."

      def copy_initializer
        template "can_play.rb", "config/initializers/can_play.rb"
      end

      def copy_locale
        copy_file "../../../config/locales/zh-Cn.yml", "config/locales/can_play.zh-CN.yml"
      end

    end
  end
end