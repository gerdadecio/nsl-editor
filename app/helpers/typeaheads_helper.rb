# frozen_string_literal: true

# View helpers shared by the stimulus-autocomplete suggestion fragments
# (app/views/shared/_autocomplete_suggestions.html.erb), whichever
# controller renders them.
module TypeaheadsHelper
  # Wraps case-insensitive occurrences of +term+ in <strong> tags within
  # +text+, matching the highlighting typeahead.js used to do automatically
  # (via its `highlight: true` option) for suggestion dropdowns. Escapes
  # everything else, so this is safe to mark html_safe once built.
  #
  # Like typeahead.js's own highlighting, this is a plain substring match:
  # it doesn't repeat the accent-folding the underlying suggestion query
  # itself uses (see Name::Scopable#lower_full_name_like), so an accented
  # match found by the query may not visibly highlight here. That's the
  # same limitation the legacy widget had.
  def highlight_typeahead_match(text, term)
    return ERB::Util.html_escape(text) if term.blank?

    escaped_term = Regexp.escape(term.strip)
    return ERB::Util.html_escape(text) if escaped_term.blank?

    text.split(/(#{escaped_term})/i).map.with_index do |part, index|
      escaped_part = ERB::Util.html_escape(part)
      index.odd? ? "<strong>#{escaped_part}</strong>" : escaped_part
    end.join.html_safe # rubocop:disable Rails/OutputSafety
  end
end
