require 'ror_hack'
require 'consul'
require 'cancancan'
require "can_play/version"
require "can_play/power"
require "can_play/ability"
require "can_play/controller"

module CanPlay
  extend ActiveSupport::Concern

  included do
    @groups        = []
    @current_group = nil
    @resources     = []
  end

  module ClassMethods

    # 为每个 resource 添加一个 group, 方便管理
    def group(opts, &block)
      if opts.is_a?(Hash)
        opts  = opts.with_indifferent_access
        group = {name: opts.delete(:name), klass: opts.delete(:klass)}
      elsif opts.is_a?(Module)
        name  = opts.try(:table_name) || opts.name.underscore
        group = {name: name, klass: opts}
      else
        # do nothing
      end
      @groups << group.with_indifferent_access
      @groups        = @groups.uniq { |i| i[:name] }
      @current_group = group
      block.call(group[:klass])
      @current_group = nil
    end

    def limit(name=nil, &block)
      raise "Need define group first" if @current_group.nil?
      Power.power(name||@current_group[:name], &block)
    end

    def collection(verb_or_verbs, object, &block)
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
          add_resource(group, verb, object, 'collection', behavior)
        end
      else
        add_resource(group, verb_or_verbs, object, 'collection', behavior)
      end
    end

    def member(verb_or_verbs, object, &block)
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
          add_resource(group, verb, object, 'member', behavior)
        end
      else
        add_resource(group, verb_or_verbs, object, 'member', behavior)
      end
    end

    def add_resource(group, verb, object, type, behavior)
      name     = "#{verb}_#{object.to_s.underscore}"
      resource = {
        name:     name,
        group:    group,
        verb:     verb,
        object:   object,
        type:     type,
        behavior: behavior
      }.with_indifferent_access
      @resources.keep_if { |i| i[:name] != name }
      @resources << resource
    end

    def find_by_name(name)
      resource = @resources.find { |r| r[:name] == name }
      raise "not found resource by name: #{name}" if resource.nil?
      resource
    end

    def grouped_resources
      @grouped_resources ||= @resources.group_by { |i| i[:group] }
    end

    def my_resources
      @resources
    end

    def grouped_resources_with_chinese_desc
      grouped_resources.tap do |i|
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
end
