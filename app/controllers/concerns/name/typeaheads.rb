module Name::Typeaheads
  extend ActiveSupport::Concern

  # For the typeahead search.
  def name_parent_suggestions
    typeahead = Name::AsTypeahead::ForParent.new(params)
    render json: typeahead.suggestions
  end

  def name_family_suggestions
    typeahead = Name::AsTypeahead::ForFamily.new(params)
    render json: typeahead.suggestions
  end

  # Columns such as parent and duplicate_of_id use a typeahead search.
  def cultivar_parent_suggestions
    render json: [] if params[:term].blank?
    render json: Name::AsTypeahead \
      .cultivar_parent_suggestions(params[:term],
                                   params[:name_id],
                                   params[:rank_id])
  end

  # Columns such as parent and duplicate_of_id use a typeahead search.
  def hybrid_parent_suggestions
    render json: [] if params[:term].blank?
    render json: Name::AsTypeahead \
      .hybrid_parent_suggestions(params[:term],
                                 params[:name_id],
                                 params[:rank_id])
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
