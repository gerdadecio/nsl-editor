# frozen_string_literal: true

module Loader::Name::SeqCalculator
  extend ActiveSupport::Concern

  included do
    def self.calc_seq(params)
      return params["seq"] if params["seq"]

      within_genus = seek_within_genus(params)
      Rails.logger.debug { "within_genus: #{within_genus}" }
      return within_genus if within_genus

      within_family = seek_within_family(params)
      Rails.logger.debug { "within_family: #{within_family}" }
      return within_family if within_family

      0
    end

    def self.seek_within_family(params)
      batch = which_batch(params)
      batch.loader_names
        .where(simple_name: params["family"])
        .where(rank: "family")
        .first
        .seq + 1
    rescue => e
      Rails.logger.error("Error in seek_within_family: #{e}")
      false
    end

    def self.seek_within_genus(params)
      first_word = params["simple_name"].sub(/ .*/, "")
      first_wild_s = "#{first_word}%"
      batch = which_batch(params)
      batch.loader_names
        .where(["simple_name like ?", "#{first_wild_s}"])
        .where("record_type in ('accepted','excluded')")
        .order("id")
        .first
        .seq - 1
    rescue => e
      Rails.logger.error("Error in seek_within_species: #{e}")
      Rails.logger.debug("Nothing found in that genus")
      false
    end

    def self.consider_seq(params)
      Rails.logger.debug { "params: #{params.inspect}" }
      return false if params["seq"]

      batch = which_batch(params)
      if batch.nil?
        false
      elsif batch.use_sort_key_for_ordering
        false
      else
        true
      end
    end

    def self.which_batch(params)
      if params["loader_batch_id"]
        Loader::Batch.find(params["loader_batch_id"])
      elsif params["parent_id"]
        Loader::Name.find(params["parent_id"]).loader_batch
      end
    end
  end
end
