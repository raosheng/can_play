require 'ror_hack'
require 'consul'
require 'cancancan'
require "can_play/version"
require "can_play/power"
require "can_play/ability"
require "can_play/controller"

module CanPlay
  mattr_accessor :resources
  @@resources = []

  class << self
    def included(base)
      base.class_eval <<-RUBY
        include RorHack::ClassLevelInheritableAttributes
        inheritable_attributes(:groups, :current_group, :module_name)
        @groups        = []
        @current_group = nil
        @module_name = ''
      RUBY
      base.extend ClassMethods
    end

    def find_by_name(name)
      CanPlay.resources.find { |r| r.name == name }
    end

    def grouped_resources
      @grouped_resources ||= CanPlay.resources.multi_group_by(:module_name, :group)
    end

    def splat_grouped_resources
      @grouped_resources ||= CanPlay.resources.multi_group_by(:group)
    end

    def my_resources
      CanPlay.resources
    end

    def grouped_resources_with_chinese_desc
      grouped_resources.tap do |e|
        e.each do |i, v|
          v.each do |group, resources|
            group.chinese_desc = begin
              name = I18n.t("can_play.class_name.#{group.name.to_s.singularize}", default: '')
              name = group.klass.model_name.human if name.blank?
              name
            end
            resources.each do |resource|
              resource.chinese_desc = I18n.t("can_play.authority_name.#{group.name.to_s.singularize}.#{resource.verb}", default: '').presence || I18n.t("can_play.authority_name.common.#{resource.verb}")
            end
          end
          v.rehash
        end
      end
    end

    def splat_grouped_resources_with_chinese_desc
      splat_grouped_resources.tap do |i|
        i.each do |group, resources|
          group[:chinese_desc] = begin
            name = I18n.t("can_play.class_name.#{group[:name].singularize}", default: '')
            name = group[:klass].model_name.human if name.blank?
            name
          end
          resources.each do |resource|
            resource[:chinese_desc] = I18n.t("can_play.authority_name.#{group[:name].singularize}.#{resource[:verb]}", default: '').presence || I18n.t("can_play.authority_name.common.#{resource[:verb]}")
          end
        end
        i.rehash
      end
    end
  end

  module Config
    mattr_accessor :user_class_name, :role_class_name, :role_resources_middle_class_name
    @@user_class_name = 'User'
    @@role_class_name = 'Role'
    @@role_resources_middle_class_name = 'RoleResource'

    def self.setup
      yield self
    end
  end



  module ClassMethods

    # 为每个 resource 添加一个 group, 方便管理
    def group(opts, &block)
      if opts.is_a?(Hash)
        opts  = opts.with_indifferent_access
        group =  OpenStruct.new(name: opts.delete(:name).to_s, klass: opts.delete(:klass))
      elsif opts.is_a?(Module)
        name = opts.try(:table_name).presence || opts.to_s.underscore.gsub('/', '_').pluralize
        group =  OpenStruct.new(name: name, klass: opts)
      else
        # do nothing
      end
      @groups << group
      @groups        = @groups.uniq(&:name)
      @current_group = group
      block.call(group.klass)
      @current_group = nil
    end

    def limit(name=nil, &block)
      raise "Need define group first" if @current_group.nil?
      Power.power(name||@current_group.name, &block)
    end

    def collection(verb_or_verbs, &block)
      raise "Need define group first" if @current_group.nil?
      group    = @current_group
      behavior = nil
      if block
        behavior = lambda do |user|
          # 在block定义的binding里，注入user这个变量。
          old_binding = block.binding
          old_binding.eval("user=nil;lambda {|v| user = v}").call(user)
          block.call_with_binding(old_binding)
        end
      end

      if verb_or_verbs.kind_of?(Array)
        verb_or_verbs.each do |verb|
          add_resource(group, verb, group.klass, 'collection', behavior)
        end
      else
        add_resource(group, verb_or_verbs, group.klass, 'collection', behavior)
      end
    end

    def member(verb_or_verbs, &block)
      raise "Need define group first" if @current_group.nil?
      group    = @current_group
      behavior = nil
      if block
        behavior = lambda do |user, obj|
          # 在block定义的binding里，注入user这个变量。
          old_binding = block.binding
          old_binding.eval("user=nil;lambda {|v| user = v}").call(user)
          block.call_with_binding(old_binding, obj)
        end
      end

      if verb_or_verbs.kind_of?(Array)
        verb_or_verbs.each do |verb|
          add_resource(group, verb, group.klass, 'member', behavior)
        end
      else
        add_resource(group, verb_or_verbs, group.klass, 'member', behavior)
      end
    end

    def add_resource(group, verb, object, type, behavior)
      name     = "#{verb}_#{group.name}"
      resource = OpenStruct.new(
        module_name: module_name,
        name:     name,
        group:    group,
        verb:     verb,
        object:   object,
        type:     type,
        behavior: behavior
      )
      CanPlay.resources.keep_if { |i| i.name != name }
      CanPlay.resources << resource
    end
  end
end
