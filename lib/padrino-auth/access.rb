require 'padrino-auth/permissions'

module Padrino
  ##
  # Padrino authorization module.
  #
  # @example
  #   class Nifty::Application < Padrino::Application
  #     # optional settings
  #     set :credentials_reader, :visitor # the name of getter method in helpers
  #     # required statement
  #     register Padrino::Access
  #     # example persistance storage
  #     enable :sessions
  #   end
  #
  #   # optional helpers
  #   Nifty::Application.helpers do
  #     def visitor
  #       session[:visitor] ||= Visitor.guest_account
  #     end
  #   end
  #
  #   # example visitor model
  #   module Visitor
  #     extend self
  #     def guest_account
  #       OpenStruct.new(:role => :guest, :id => 1)
  #     end
  #   end
  #
  #   # example controllers
  #   Nifty::Application.controller :public_area do
  #     set_access :*
  #     get(:index){ 'public content' }
  #   end
  #   Nifty::Application.controller :members_area do
  #     set_access :member
  #     get(:index){ 'secret content' }
  #   end
  #   Nifty::Application.controller :login do
  #     set_access :*
  #     get(:index){ session[:visitor] = OpenStruct.new(:role => :guest, :id => 1) }
  #   end
  #
  module Access
    class << self
      def registered(app)
        included(app)
        app.default(:credentials_reader, :credentials)
        app.default(:access_errors, true)
        app.send :attr_reader, app.credentials_reader unless app.instance_methods.include?(app.credentials_reader)
        app.set :permissions, Permissions.new
        app.login_permissions if app.respond_to?(:login_permissions)
        app.before do
          authorized? || error(403, '403 Forbidden')
        end
      end

      def included(base)
        base.send(:include, InstanceMethods)
        base.extend(ClassMethods)
      end
    end

    module ClassMethods
      ##
      # Empties the list of permission.
      #
      def reset_access!
        permissions.clear!
      end

      ##
      # Allows access to action with objects.
      #
      # @example
      #   # in application
      #   set_access :*, :with => :login # allows everyone to interact with :login controller
      #   # in controller
      #   App.controller :members_area do
      #     set_access :member # allows all members to access :members_area controller
      #   end
      #
      def set_access(*args)
        options = args.extract_options!
        options[:object] ||= Array(@_controller).first.to_s.singularize.to_sym if @_controller.present?
        permissions.add(*args, options)
      end
    end

    module InstanceMethods
      ##
      # Checks if current visitor has access to current action with current controller.
      #
      def authorized?
        access_action?
      end

      ##
      # Returns current visitor.
      #
      def access_subject
        send settings.credentials_reader
      end

      ##
      # Checks if current visitor is one of the specified roles. Can accept a block.
      #
      def access_role?(*roles, &block)
        settings.permissions.check(access_subject, :have => roles, &block)
      end

      ##
      # Checks if current visitor is allowed to to the action with object. Can accept a block.
      #
      def access_action?(action = nil, object = nil, &block)
        return true if response.status/100 == 4 && settings.access_errors
        if respond_to?(:request) && action.nil? && object.nil?
          object = request.controller
          action = request.action
          if object.nil? && action.present? && action.to_s.index('/')
            object, action = request.env['PATH_INFO'].to_s.scan(/\/([^\/]*)/).map(&:first)
          end
          object ||= :''
          action ||= :index
          object = object.to_sym
          action = action.to_sym
        end
        settings.permissions.check(access_subject, :allow => action, :with => object, &block)
      end

      ##
      # Check if current visitor is allowed to interact with object by action. Can accept a block.
      #
      def access_object?(object = nil, action = nil, &block)
        allow_action action, object, &block
      end

      ##
      # Populates the list of objects the current visitor is allowed to interact with.
      #
      def access_objects(subject = access_subject, action = nil)
        settings.permissions.find_objects(subject, action)
      end
    end
  end
end
