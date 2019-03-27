# frozen_string_literal: true
module Stupidedi
  using Refinements

  module Versions
    module Common
      module ElementTypes
        class Nn < SimpleElementDef
          # @return [Integer]
          attr_reader :precision

          def initialize(id, name, min_length, max_length, precision, description = nil, parent = nil)
            super(id, name, min_length, max_length, description, parent)

            if precision > max_length
              raise Exceptions::InvalidSchemaError,
                "precision cannot be greater than max_length"
            end

            @precision = precision
          end

          # @return [Nn]
          def copy(changes = {})
            Nn.new \
              changes.fetch(:id, @id),
              changes.fetch(:name, @name),
              changes.fetch(:min_length, @min_length),
              changes.fetch(:max_length, @max_length),
              changes.fetch(:precision, @precision),
              changes.fetch(:description, @description),
              changes.fetch(:parent, @parent)
          end

          def companion
            FixnumVal
          end
        end

        #
        # @see X222.pdf B.1.1.3.1.1 Numeric
        #
        class FixnumVal < Values::SimpleElementVal
          def numeric?
            true
          end

          def too_long?
            false
          end

          def too_short?
            false
          end

          class Invalid < FixnumVal
            # @return [Object]
            attr_reader :value

            def initialize(value, usage, position)
              @value = value
              super(usage, position)
            end

            def valid?
              false
            end

            def empty?
              false
            end

            # @return [FixnumVal]
            def map
              self
            end

            # @return [String]
            # :nocov:
            def inspect
              id = definition.bind do |d|
                "[#{"% 5s" % d.id}: #{d.name}]".bind do |s|
                  if usage.forbidden?
                    ansi.forbidden(s)
                  elsif usage.required?
                    ansi.required(s)
                  else
                    ansi.optional(s)
                  end
                end
              end

              ansi.element("Nn.invalid#{id}") + "(#{ansi.invalid(@value.inspect)})"
            end
            # :nocov:

            # @return [String]
            def to_s
              ""
            end

            # @return [String]
            def to_x12(truncate = true)
              ""
            end

            # @return [Boolean]
            def ==(other)
              eql?(other)
            end

            # @return [Invalid]
            def copy(changes = {})
              self
            end
          end

          class Valid < FixnumVal
            def valid?
              true
            end

            # @return [FixnumVal]
            def map
              FixnumVal.value(yield(value), usage, position)
            end

            # @return [Empty]
            def copy(changes = {})
              FixnumVal.value \
                changes.fetch(:value, value),
                changes.fetch(:usage, usage),
                changes.fetch(:position, position)
            end

            def coerce(other)
              return FixnumVal.value(other, usage, position), self
            end

            def ==(other)
              other = FixnumVal.value(other, usage, position)
              other.valid? and other.value == value
            end
          end

          #
          # Empty numeric value. Shouldn't be directly instantiated -- instead
          # use the {FixnumVal.value} and {FixnumVal.empty} constructors.
          #
          class Empty < Valid
            def value
              nil
            end

            def empty?
              true
            end

            # @return [String]
            # :nocov:
            def inspect
              id = definition.bind do |d|
                "[#{"% 5s" % d.id}: #{d.name}]".bind do |s|
                  if usage.forbidden?
                    ansi.forbidden(s)
                  elsif usage.required?
                    ansi.required(s)
                  else
                    ansi.optional(s)
                  end
                end
              end

              ansi.element("Nn.empty#{id}")
            end
            # :nocov:

            # @return [String]
            def to_s
              ""
            end

            # @return [String]
            def to_x12(truncate = true)
              ""
            end
          end

          #
          # Non-empty numeric value. Shouldn't be directly instantiated --
          # instead, use the {FixnumVal.value} constructors.
          #
          class NonEmpty < Valid
            # @group Mathematical Operators
            #################################################################

            extend Operators::Binary
            binary_operators :+, :-, :*, :/, :%, :coerce => :to_d

            extend Operators::Unary
            unary_operators :abs, :-@, :+@

            extend Operators::Relational
            relational_operators :<, :>, :<=, :>=, :<=>, :coerce => :to_d

            # @endgroup
            #################################################################

            # @return [BigDecimal]
            attr_reader :value

            def_delegators :value, :to_i, :to_d, :to_f, :to_r, :to_c

            def initialize(value, usage, position)
              @value = value
              super(usage, position)
            end

            def empty?
              false
            end

            def too_long?
              nn = (@value * (10 ** definition.precision)).to_i

              # The length of a numeric type does not include an optional sign
              definition.max_length < nn.abs.to_s.length
            end

            # @return [String]
            # :nocov:
            def inspect
              id = definition.bind do |d|
                "[#{"% 5s" % d.id}: #{d.name}]".bind do |s|
                  if usage.forbidden?
                    ansi.forbidden(s)
                  elsif usage.required?
                    ansi.required(s)
                  else
                    ansi.optional(s)
                  end
                end
              end

              ansi.element("Nn.value#{id}") + "(#{@value.to_s("F").gsub(/\.0+$/, "")})"
            end
            # :nocov:

            # @return [String]
            def to_s
              # The number of fractional digits is implied by usage.precision
              @value.to_s("F").gsub(/\.0+$/, "")
            end

            # @return [String]
            def to_x12(truncate = true)
              nn   = (@value * (10 ** definition.precision)).to_i
              sign = (nn < 0) ? "-" : ""

              # Leading zeros must be suppressed unless necessary to satisfy a
              # minimum length requirement
              if truncate
                sign = sign + nn.abs.to_s.
                  take(definition.max_length).
                  rjust(definition.min_length, "0")
              else
                sign = sign + nn.abs.to_s.
                  rjust(definition.min_length, "0")
              end
            end
          end
        end

        class << FixnumVal
          # @group Constructors
          ###################################################################

          # @return [FixnumVal]
          def empty(usage, position)
            self::Empty.new(usage, position)
          end

          # @return [FixnumVal]
          def value(object, usage, position)
            if object.is_a?(FixnumVal)
              object#.copy(:usage => usage, :position => position)
            elsif object.blank?
              self::Empty.new(usage, position)
            elsif object.is_a?(String)
              # The number of fractional digits is implied by usage.precision
              factor = 10 ** usage.definition.precision
              self::NonEmpty.new(object.to_d / factor, usage, position)
            else
              self::NonEmpty.new(object.to_d, usage, position)
            end
          rescue ArgumentError
            self::Invalid.new(object, usage, position)
          end

          # @endgroup
          ###################################################################
        end

        # Prevent direct instantiation of abstract class FixnumVal
        FixnumVal.eigenclass.send(:protected, :new)
        FixnumVal::Empty.eigenclass.send(:public, :new)
        FixnumVal::Invalid.eigenclass.send(:public, :new)
        FixnumVal::NonEmpty.eigenclass.send(:public, :new)
      end
    end
  end
end
