# frozen_string_literal: true
module Stupidedi
  module Interchanges
    module FiveOhOne
      s = Schema
      r = Versions::FiftyTen::ElementReqs

      InterchangeDef = Class.new(Schema::InterchangeDef) do
        # @group Constructors
        #####################################################################

        # @return [Values::InterchangeVal]
        def empty(separators)
          Values::InterchangeVal.new(self, [], separators)
        end

        # @endgroup
        #####################################################################

        # @return [Module]
        def segment_dict
          SegmentDefs
        end

        # @return [Reader::Separators]
        def separators(isa)
          Reader::Separators.new(isa.element(16).to_s, isa.element(11).to_s, nil, nil)
        end

        # @return [SegmentVal]
        def replace_separators(isa, separators)
          isa.copy \
            :separators => separators,
            :children   =>
              [isa.element(1),
               isa.element(2),
               isa.element(3),
               isa.element(4),
               isa.element(5),
               isa.element(6),
               isa.element(7),
               isa.element(8),
               isa.element(9),
               isa.element(10),
               isa.element(11).copy(:value => separators.repetition),
               isa.element(12),
               isa.element(13),
               isa.element(14),
               isa.element(15),
               isa.element(16).copy(:value => separators.component)]
        end
      end.new "00501",
        [ SegmentDefs::ISA.use(1, r::Mandatory, s::RepeatCount.bounded(1)),
          SegmentDefs::TA1.use(4, r::Optional,  s::RepeatCount.unbounded) ],
        [ SegmentDefs::IEA.use(5, r::Mandatory, s::RepeatCount.bounded(1)) ]

    end
  end
end
