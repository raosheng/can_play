require "can_play/version"
require "can_play/power"
require "can_play/ability"
require "can_play/controller"

module CanPlay
  extend ActiveSupport::Concern

  included do
    @groups = []
    @current_group = nil
    @resources = []
  end

  module ClassMethods

    # 为每个 resource 添加一个 group, 方便管理
    def group(name, &block)
      @groups << name
      @groups.uniq!
      @current_group = name
      block.call
      @current_group = nil
    end

    def power(&block)
      raise "Need define group first" if @current_group.nil?
      Power.power(@current_group, &block)
    end

    def source(verb_or_verbs, object, &block)
      raise "Need define group first" if @current_group.nil?
      group = @current_group
      behavior = block
      if verb_or_verbs.kind_of?(Array)
        verb_or_verbs.each do |verb|
          add_resource(group, verb, object, behavior)
        end
      else
        add_resource(group, verb_or_verbs, object, behavior)
      end
    end

    def add_resource(group, verb, object, behavior)
      name = "#{verb}_#{object.to_s.underscore}"
      resource = {
        name: name,
        group: group,
        verb: verb,
        object: object,
        behavior: behavior,
      }
      @resources.keep_if {|i| i[:name] != name}
      @resources << resource
    end

    def each_group(&block)
      @groups.each do |group|
        block.call(group)
      end
    end

    def each_resources_by(group, &block)
      resources = @resources.find_all { |r| r[:group] == group }
      resources.each(&block)
    end

    def find_by_name(name)
      resource = @resources.find { |r| r[:name] == name }
      raise "not found resource by name: #{name}" if resource.nil?
      resource
    end

    def grouped_resources
      @resources.group_by {|i| i[:group]}
    end

    def my_resources
      @resources
    end

  end
end
