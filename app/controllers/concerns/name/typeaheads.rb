module Name::Typeaheads
  extend ActiveSupport::Concern

  # For the typeahead search.
  #
  # Two response formats over the one query, matching
  # AuthorsController#typeahead_on_abbrev:
  #   json - kept for parity with the other suggestion actions; nothing in
  #          this app's own views still asks for it.
  #   html - the fragment of <li role="option"> elements stimulus-autocomplete
  #          expects, see app/views/shared/_autocomplete_suggestions.html.erb.
  #          The name form's Parent field asks for this by extension - see
  #          AuthorsController#typeahead_on_abbrev's comment for why the format
  #          has to be pinned that way rather than left to the Accept header.
  #
  # data_keys publishes each suggestion's family alongside its id, because
  # choosing a parent also fills in the form's Family field - see
  # app/javascript/controllers/name_parent_family_controller.js.
  def name_parent_suggestions
    typeahead = Name::AsTypeahead::ForParent.new(params)
    respond_to do |format|
      format.json { render json: typeahead.suggestions }
      format.html do
        render partial: "shared/autocomplete_suggestions",
               locals: { suggestions: typeahead.suggestions,
                         term: params[:term],
                         data_keys: %i[family_id family_value] }
      end
    end
  end

  # For the name form's Family field.
  #
  # Two response formats over the one query, as for #name_parent_suggestions
  # above:
  #   json - kept for parity with the other suggestion actions; nothing in
  #          this app's own views still asks for it.
  #   html - the fragment of <li role="option"> elements stimulus-autocomplete
  #          expects, which the Family field asks for by extension.
  def name_family_suggestions
    typeahead = Name::AsTypeahead::ForFamily.new(params)
    respond_to do |format|
      format.json { render json: typeahead.suggestions }
      format.html do
        render partial: "shared/autocomplete_suggestions",
               locals: { suggestions: typeahead.suggestions,
                         term: params[:term] }
      end
    end
  end

  # Suggests the parent of a cultivar name.
  #
  # Answers json to the second parent field, still on typeahead.js, and html
  # to the Parent field - see #name_parent_suggestions. No family is sent
  # with a cultivar's suggestions, so picking one leaves the Family field
  # alone, as it always has.
  def cultivar_parent_suggestions
    suggestions = Name::AsTypeahead \
      .cultivar_parent_suggestions(params[:term],
                                   params[:name_id],
                                   params[:rank_id])
    render_parent_suggestions(suggestions)
  end

  # Suggests the parent of a hybrid name. As for cultivars above.
  def hybrid_parent_suggestions
    suggestions = Name::AsTypeahead \
      .hybrid_parent_suggestions(params[:term],
                                 params[:name_id],
                                 params[:rank_id])
    render_parent_suggestions(suggestions)
  end

  # Columns such as parent and duplicate_of_id use a typeahead search.
  #
  # Two response formats over the one query, matching
  # AuthorsController#typeahead_on_abbrev:
  #   json - answered for any caller that doesn't ask for html by extension
  #          (kept for parity with that action; nothing in this app's own
  #          views still asks for it).
  #   html - the fragment of <li role="option"> elements stimulus-autocomplete
  #          expects, see app/views/shared/_autocomplete_suggestions.html.erb.
  #          The name form's Duplicate of field asks for this by extension -
  #          see AuthorsController#typeahead_on_abbrev's comment for why the
  #          format has to be pinned that way rather than left to the Accept
  #          header.
  def duplicate_suggestions
    suggestions = duplicate_suggestions_typeahead
    respond_to do |format|
      format.json { render json: suggestions }
      format.html do
        render partial: "shared/autocomplete_suggestions",
               locals: { suggestions: suggestions, term: params[:term] }
      end
    end
  end

  # Used on references - new instance tab
  def typeahead_on_full_name
    typeahead = Name::AsTypeahead::OnFullName.new(params)
    render json: typeahead.suggestions
  end

  private

  def render_parent_suggestions(suggestions)
    respond_to do |format|
      format.json { render json: suggestions }
      format.html do
        render partial: "shared/autocomplete_suggestions",
               locals: { suggestions: suggestions, term: params[:term] }
      end
    end
  end

  def typeahead_params
    params.require(:name).permit(:author_id,
                                 :ex_author_id,
                                 :base_author_id,
                                 :ex_base_author_id,
                                 :sanctioning_author_id,
                                 :author_typeahead,
                                 :ex_author_typeahead,
                                 :base_author_typeahead,
                                 :ex_base_author_typeahead,
                                 :sanctioning_author_typeahead,
                                 :family_id,
                                 :family_typeahead,
                                 :parent_id,
                                 :second_parent_id,
                                 :parent_typeahead,
                                 :second_parent_typeahead,
                                 :duplicate_of_id,
                                 :duplicate_of_typeahead)
  end
end
