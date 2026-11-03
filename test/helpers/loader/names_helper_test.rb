# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#   This file is part of the NSL Editor.
#   Licensed under the Apache License, Version 2.0

require "test_helper"

# Tests for the name shown for a loader name in print output.
class Loader::NamesHelperTest < ActionView::TestCase
  include Loader::NamesHelper

  def loader_name(simple_name, rank)
    Loader::Name.new(simple_name: simple_name, full_name: "#{simple_name} Auth.", rank: rank)
  end

  test "species prints its simple name, without authority" do
    assert_equal "Hardenbergia violacea", loader_name_print_name(loader_name("Hardenbergia violacea", "species"))
  end

  test "genus prints its simple name upcased" do
    assert_equal "BANKSIA", loader_name_print_name(loader_name("Banksia", "Genus"))
  end

  test "hybrid genus keeps the x marker lower case" do
    assert_equal "x CUPROCYPARIS", loader_name_print_name(loader_name("x Cuprocyparis", "genus"))
  end

  test "hybrid genus keeps the multiplication sign marker" do
    assert_equal "×CUPROCYPARIS", loader_name_print_name(loader_name("×Cuprocyparis", "genus"))
  end

  test "genus starting with X is not treated as a hybrid" do
    assert_equal "XANTHORRHOEA", loader_name_print_name(loader_name("Xanthorrhoea", "genus"))
  end

  test "missing rank prints the simple name unchanged" do
    assert_equal "Banksia", loader_name_print_name(loader_name("Banksia", nil))
  end
end
