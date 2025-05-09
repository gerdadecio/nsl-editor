#
# Always show concept-notes and distributions
# Optionally show review comments
class Search::Loader::Name::RewriteResultsShowingExtras
  def initialize(results, show_review_comments)
    @show_review_comments = show_review_comments
    @results = results
  end

  def rewrite_results
    @results_with_comments = []
    @waiting_for_next_top_level_record = false
    @first_top_level_record = true
    @results.each do |rec|
      one_record(rec)
    end
    flush_data_for_last_record
    @results_with_comments
  end

  private

  def one_record(rec)
    top_level_record(rec) if %w[accepted excluded].include? rec[:record_type]
    push_preceding if %w[in-batch-note in-batch-compiler-note heading].include? rec[:record_type]
    @results_with_comments << formatted_text_above(rec) unless rec.formatted_text_above.blank?
    @results_with_comments << rec
    @results_with_comments << formatted_text_below(rec) unless rec.formatted_text_below.blank?
    review_comments(rec) if @show_review_comments
  end

  def top_level_record(rec)
    if @first_top_level_record
      handle_first_top_level_record(rec)
    else
      handle_second_or_later_top_level_record(rec)
    end
  end

  def handle_first_top_level_record(rec)
    @first_top_level_record = false
    @previous_top_level_rec = rec.clone
    @waiting_for_next_top_level_record = true
  end

  def handle_second_or_later_top_level_record(rec)
    push_preceding
    @previous_top_level_rec = rec.clone
    @waiting_for_next_top_level_record = true
  end

  def push_preceding
    return if @previous_top_level_rec.nil?

    concept_note_and_cn_comments(@previous_top_level_rec)
    dist_and_dist_comments(@previous_top_level_rec)
    @previous_top_level_rec = nil
  end

  def flush_data_for_last_record
    push_preceding
  end

  def dist_and_dist_comments(rec)
    dist(rec)
    dist_comments(rec)
  end

  def dist(rec)
    return if rec["distribution"].blank?

    dist = {}
    dist[:display_as] = "Loader Name"
    dist[:record_type] = "distribution"
    dist[:payload] = rec["distribution"]
    @results_with_comments << dist
  end

  def dist_comments(rec)
    return unless @show_review_comments

    dist_comments = Loader::Name::Review::Comment::AsArray::ForLoaderName
                    .new(rec, "distribution")
    dist_comments.results.each { |i| @results_with_comments << i }
  end

  def concept_note_and_cn_comments(rec)
    concept_note(rec)
    cn_comments(rec)
  end

  def concept_note(rec)
    return if rec["comment"].blank?

    h = {}
    h[:display_as] = "Loader Name"
    h[:record_type] = "concept-note"
    h[:payload] = rec["comment"]
    @results_with_comments << h
  end

  def cn_comments(rec)
    return unless @show_review_comments

    comments_query = Loader::Name::Review::Comment::AsArray::ForLoaderName
                     .new(rec, "concept-note")
    comments_query.results.each { |i| @results_with_comments << i }
  end

  def review_comments(rec)
    comments_query = Loader::Name::Review::Comment::AsArray::ForLoaderName
                     .new(rec, rec[:record_type])
    comments_query.results.each { |i| @results_with_comments << i }
  end

  def formatted_text_above(rec)
    h = {}
    h[:display_as] = "Loader Name"
    h[:record_type] = "formatted-text-above"
    h[:formatted_text_above] = rec.formatted_text_above
    h
  end

  def formatted_text_below(rec)
    h = {}
    h[:display_as] = "Loader Name"
    h[:record_type] = "formatted-text-below"
    h[:formatted_text_below] = rec.formatted_text_below
    h
  end

  def debug(s)
    # Rails.logger.debug("========= #{s} =====================================")
  end
end
