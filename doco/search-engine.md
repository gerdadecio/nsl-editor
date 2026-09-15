## Search Engine

Deeper notes on the query pipeline summarised in the [README's Search Mechanism section](../README.md#search-mechanism). Start there for the top-level picture (Search Request → Search Model → old/new engine → Parse Request → Convert Directives to SQL → Execute SQL → Display Results); this doc drills into the boxes that section doesn't have room for.

Sections will be added here as each part of the pipeline is documented in detail:

- Parsing pipeline - everything `Search::ParsedRequest` does to a raw query string (directives, defaults, target resolution)
- Query-building pipeline - `WhereClauses` → `NextCriterion` → `Predicate` → `FieldRule`/YAML → the ActiveRecord chain
- The generic `Search::OnModel::Base` engine - how one class serves author, reference, org, users, and the loader/batch targets by loading a different `FieldRule` module per target
- Defined queries - the separate, non-tokenized query path (audit, cross-table reports)

_(placeholder - to be filled in)_
