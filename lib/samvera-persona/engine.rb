require 'rubygems'
require 'paranoia'
require 'pretender'

module Samvera
  module Persona
    class Engine < ::Rails::Engine
      isolate_namespace Samvera::Persona

      initializer :append_migrations do |app|
        unless app.root.to_s.match root.to_s
          config.paths["db/migrate"].expanded.each do |expanded_path|
            app.config.paths["db/migrate"] << expanded_path
          end
        end
      end

      config.generators do |g|
        g.test_framework :rspec, :fixture => false
        g.fixture_replacement :factory_bot, :dir => 'spec/factories'
        g.assets false
        g.helper false
      end

      config.before_initialize do
        config.i18n.load_path += Dir["#{config.root}/config/locales/**/*.yml"]
      end

      config.after_initialize do
        my_engine_root = Samvera::Persona::Engine.root.to_s
        paths = ActionController::Base.view_paths.collect{|p| p.to_s}
        hyrax_path = paths.detect { |path| path.match('/hyrax-') }
        if hyrax_path
          paths = paths.insert(paths.index(hyrax_path), my_engine_root + '/app/views')
        else
          paths = paths.insert(0, my_engine_root + '/app/views')
        end
        ActionController::Base.view_paths = paths
        ::ApplicationController.send :include, Samvera::Persona::BecomesBehavior
        ::Devise::InvitationsController.define_method :after_invite_path_for do |_resource|
          admin_users_path
        end
      end

      config.to_prepare do
        User.send :include, Samvera::Persona::SoftDeleteBehavior
      end

    end
  end
end