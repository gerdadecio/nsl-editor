# frozen_string_literal: true

module Loader::Name::SortKey
  extend ActiveSupport::Concern

  def consider_sort_key
    if loader_batch.use_sort_key_for_ordering
      set_sort_key if sort_key.blank?
      set_sort_key if should_reset_sort_key?
    else
      self.sort_key = nil
    end
  end

  def should_reset_sort_key?
    return false if ["in-batch-note", "in-batch-compile-note", "heading"].include?(record_type)
    return true if changed? && !changes_to_save.keys.include?("sort_key")

    false
  end

  def set_sort_key
    normalise_sort_key if sort_key.present?
    self.sort_key = case record_type
    when "accepted"
      if rank.downcase == "family"
        "#{family.downcase}.family"
      else
        "#{family.downcase}.family.#{record_type}.#{simple_name.downcase} #{"1genus" if rank == "genus"}"
      end
    when "excluded"
      if rank.downcase == "family"
        "#{family.downcase}.family"
      else
        "#{family.downcase}.family.#{record_type}.#{simple_name.downcase} #{"1genus" if rank == "genus"}"
      end
    when "synonym"
      synonym_sort_key(parent.sort_key)
    when "misapplied"
      misapp_sort_key(parent.sort_key)
    when "heading"
      if rank.blank? || rank.downcase == "family"
        "#{family.downcase}.family"
      else
        "aaa-rank-#{rank}-heading"
      end
    when "in-batch-note"
      in_batch_note_sort_key
    when "in-batch-compiler-note"
      in_batch_compiler_note_sort_key
    else
      "aaaaaa-unexpected-record-type-#{record_type}"
    end
  rescue StandardError => e
    puts e
    puts "set_sort_key: record_type: #{record_type}; rank: #{rank}; family: #{family}"
    raise
  end

  # This is for when we are combining our sort_key algorithm with a synonym sort
  # value from taxon_mv(_new) - we want enough of a sort_key for the synonym
  # to place it under its parent, but not enough to determine its sorting
  # position within other synonyms for that parent.
  def set_short_sort_key
    normalise_sort_key if sort_key.present?
    if sort_key.blank? && record_type == "synonym"
      self.sort_key = synonym_short_sort_key(parent.sort_key)
    end
  rescue StandardError => e
    puts e
    puts "set_short_sort_key: record_type: #{record_type}; rank: #{rank}; family: #{family}"
    raise
  end

  def normalise_sort_key
    self.sort_key = sort_key.downcase unless sort_key == sort_key.downcase
  end

  def synonym_sort_key(parent_sort_key, syn_type = synonym_type)
    "#{parent_sort_key}.a-syn.#{synonym_sort_key_tail(syn_type)}"
  end

  # This is designed to leave detailed syn ordering to a key from taxon_mv
  def synonym_short_sort_key(parent_sort_key, syn_type = synonym_type)
    "#{parent_sort_key}.a-syn."
  end

  def misapp_sort_key(parent_sort_key)
    "#{parent_sort_key}.b-mis.z-mis"
  end

  def synonym_sort_key_tail(syn_type = synonym_type)
    case syn_type
    when "isonym"
      "a-isonym"
    when "orthographic variant"
      "b-orth-var"
    when "basionym"
      "c-basionym"
    when "replaced synonym"
      "d-replaced-syn"
    when "alternative name"
      "e-alt-name"
    when "nomenclatural synonym"
      "f-nom-syn"
    when "taxonomic synonym"
      "g-tax-syn"
    when "doubtful pro parte taxonomic synonym"
      "g-tax-syn"
    when "doubtful-taxonomic-synonym"
      "g-tax-syn"
    when "pro parte taxonomic synonym"
      "g-tax-syn"
    else
      "x-is-unknown-#{syn_type}"
    end
  end
end
