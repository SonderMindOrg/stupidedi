# frozen_string_literal: true
module Stupidedi
  module Versions
    module ThirtyForty
      module SegmentDefs
        s = Schema
        e = ElementDefs
        r = ElementReqs

        TDS = s::SegmentDef.build(:TDS, "Total Monetary Value Summary",
          "To specify the total invoice discounts and amounts",
          e::E361 .simple_use(r::Mandatory,  s::RepeatCount.bounded(1)))
      end
    end
  end
end
