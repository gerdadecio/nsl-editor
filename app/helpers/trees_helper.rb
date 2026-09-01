# frozen_string_literal: true

# Help for tree display
module TreesHelper
  # NOTES: The order the messages are shown in.
  TREE_USAGES = %i[current draft historical].freeze

  # NOTES: Tree changes are handed to the services and can take a few minutes
  # to appear everywhere, so place / replace / remove all say so rather than
  # let the editor assume the change was lost.
  TREE_CHANGE_DELAY_MESSAGE =
    "This change may experience a delay, please re-check in 5 minutes"

  # NOTES: The trees a record (an instance or a name) is used in, worded for
  # the delete tabs, which have to tell three kinds of usage apart:
  #
  #   current     the tree's current, published version
  #   draft       any unpublished version
  #   historical  a published version that has been superseded
  #
  # A tree version is either published or not, and a published version is
  # either the tree's current one or an older one, so every usage falls into
  # exactly one group. Each message names its trees, e.g.
  # "Instance is in the currently accepted APC, FOA trees".
  def tree_usage_messages(record)
    tree_names_by_usage(record).map do |usage, tree_names|
      tree_usage_message(record, usage, tree_names)
    end
  end

  def tree_change_delay_notice
    tag.p(TREE_CHANGE_DELAY_MESSAGE, class: "tree-change-delay-notice")
  end

  private

  # NOTES: One pass over the record's tree usage, grouped in Ruby, so all
  # three messages cost a single query on the tree_join_v view.
  def tree_names_by_usage(record)
    grouped = record.tree_join_v
      .distinct
      .order(:tree_name)
      .pluck(:tree_name, :published, :is_current_version)
      .reject { |tree_name, _published, _current| tree_name.blank? }
      .group_by { |_tree_name, published, current| tree_usage(current, published) }

    TREE_USAGES.filter_map do |usage|
      # NOTES: uniq because one tree can reach a usage by more than one
      # version - two drafts, or two superseded published versions.
      tree_names = grouped[usage]&.map(&:first)&.uniq
      [usage, tree_names] if tree_names.present?
    end
  end

  def tree_usage(current, published)
    return :current if current
    return :draft unless published

    :historical
  end

  def tree_usage_message(record, usage, tree_names)
    # NOTES: "Instance" or "Name", so one helper serves both delete tabs.
    subject = record.model_name.human
    trees = tree_names.join(", ")
    noun = "tree".pluralize(tree_names.size)

    case usage
    when :current then "#{subject} is in the currently accepted #{trees} #{noun}"
    when :draft then "#{subject} is in the #{trees} draft #{noun}"
    when :historical
      "#{subject} is in at least one old classification: #{trees} #{noun}"
    end
  end
end
