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
  # Where the name form's Parent field fetches its suggestions from, which
  # depends on the name's category: hybrid and cultivar names take their
  # parents from their own endpoints, everything else from the general one.
  # This is the choice the three typeahead.js set-up calls the field used to
  # render made (setUpNameHybridParentTypeahead,
  # setUpNameCultivarParentTypeahead and setUpNameParentTypeahead), each
  # wired to its own Bloodhound source.
  #
  # Asked for as .html so the endpoint answers the stimulus-autocomplete
  # fragment rather than the json its remaining typeahead.js callers get -
  # see AuthorsController#typeahead_on_abbrev for why the format has to be
  # pinned by extension.
  def parent_suggestions_url_for(name)
    category = name.category_for_edit
    if category.takes_hybrid_scoped_parent?
      name_hybrid_parent_suggestions_path(format: :html)
    elsif category.takes_cultivar_scoped_parent?
      name_cultivar_parent_suggestions_path(format: :html)
    else
      name_name_parent_suggestions_path(format: :html)
    end
  end

  # Where the name form's Second parent field fetches its suggestions from,
  # which also depends on the name's category: a cultivar hybrid takes its
  # second parent from the cultivar-scoped endpoint, any other hybrid from
  # the hybrid-scoped one. This is the choice the two typeahead.js set-up
  # calls the field used to render made
  # (setUpNameCultivarSecondParentTypeahead and
  # setUpNameSecondParentTypeahead), each wired to its own Bloodhound
  # source. Only categories that take a second parent render the field, so
  # there is no general fallback here.
  #
  # Asked for as .html for the same reason as #parent_suggestions_url_for.
  def second_parent_suggestions_url_for(name)
    if name.category_for_edit.takes_cultivar_scoped_parent?
      name_cultivar_parent_suggestions_path(format: :html)
    else
      name_hybrid_parent_suggestions_path(format: :html)
    end
  end

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
