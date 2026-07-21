# frozen_string_literal: true

require 'block_repeater/version'
require 'block_repeater/repeatable'
require 'block_repeater/replay'
require 'block_repeater/repeater'

##
# A class for repeating a block of code until a condition or timeout is met
# Can be accessed directly through the Repeater class or through the method
# exposed in the Repeatable module
#
module BlockRepeater
  include Repeatable
  include Replay
end
