# frozen_string_literal: true

# The assertions called in after_teardown are offset in minitest/unit.rb
# so that assertions counts with and without this are the same.  If the
# count changes, please adjust the code in unit.rb, search for zombie

module ZombieHunter
  def after_teardown
    super
    assert_empty(Process.waitall)
  end
end

Test::Unit::TestCase.include ZombieHunter
