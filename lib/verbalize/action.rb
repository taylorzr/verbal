require_relative 'build'
require_relative 'error'
require_relative 'failure'
require_relative 'success'

module Verbalize
  module Action
    THROWN_SYMBOL = :verbalize_error

    def fail!(failure_value = nil)
      throw(THROWN_SYMBOL, failure_value)
    end

    def action_inputs
      self.class.inputs.map { |i| [i, self.send(i)] }.to_h
    end

    def self.included(target)
      target.extend ClassMethods
    end

    private

    def __setup(key, value)
      is_valid = self.class.input_is_valid?(key, value)
      local_error = self.class.pop_local_error
      fail!(local_error) if !is_valid && local_error
      fail! "Input '#{key}' failed validation!" unless is_valid

      instance_variable_set(:"@#{key}", value)
    end

    module ClassMethods
      def required_inputs
        @required_inputs || []
      end

      def optional_inputs
        @optional_inputs || []
      end

      def default_inputs
        (@defaults || {}).keys
      end

      def inputs
        required_inputs + optional_inputs + default_inputs
      end

      def defaults
        @defaults
      end

      def input_validations
        @input_validations ||= {}
      end

      def input_is_valid?(input, value)
        return true unless input_validations.include?(input.to_sym)

        input_validations[input].call(value) == true
      rescue => e
        @local_error = e
        false
      end

      def pop_local_error
        return nil unless @local_error
        @local_error
      ensure
        @local_error = nil
      end

      # Because call/call! are defined when Action.input is called, they would
      # not be defined when there is no input. So we pre-define them here, and
      # if there is any input, they are overwritten
      def call
        __proxied_call
      end

      def call!
        __proxied_call!
      end
      alias_method :!, :call!

      private

      def input(*required_keywords, optional: [])
        @required_inputs = required_keywords
        optional = Array(optional)
        @optional_inputs = optional.reject { |kw| kw.is_a?(Hash) }
        assign_defaults(optional)

        class_eval Build.call(required_inputs, optional_inputs, default_inputs)
      end

      def validate(keyword, &block)
        raise Verbalize::Error, 'Missing block to validate against!' unless block_given?
        input_validations[keyword.to_sym] = block
      end

      def assign_defaults(optional)
        @defaults = optional.select { |kw| kw.is_a?(Hash) }.reduce(&:merge)
        @defaults = (@defaults || {})
                    .map { |k, v| [k, v.respond_to?(:call) ? v : -> { v }] }
                    .to_h
      end

      def perform(*args)
        new(*args).send(:call)
      end

      # We used __proxied_call/__proxied_call! for 2 reasons:
      #   1. The declaration of call/call! needs to be explicit so that tools
      #      like rspec-mocks can verify the actions keywords actually
      #      exist when stubbing
      #   2. Because #1, meta-programming a simple interface to these proxied
      #      methods is much simpler than meta-programming the full methods
      def __proxied_call(*args)
        error = catch(:verbalize_error) do
          value = perform(*args)
          return Success.new(value)
        end

        Failure.new(error)
      end

      def __proxied_call!(*args)
        perform(*args)
      rescue UncaughtThrowError => uncaught_throw_error
        fail_value = uncaught_throw_error.value
        error = Verbalize::Error.new("Unhandled fail! called with: #{fail_value.inspect}.")
        error.set_backtrace(uncaught_throw_error.backtrace[2..-1])
        raise error
      end
    end
  end
end
