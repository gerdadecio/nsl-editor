create table taxonomy_element_comment (
  id serial primary key,
  tree_element_id bigint not null,
  taxonomy_version_review_period_id bigint not null,
  comment text not null,
  lock_version bigint not null default 0,
  created_at timestamp with time zone not null,
  created_by character varying(50)    not null,
  updated_at timestamp with time zone not null,
  updated_by character varying(50)    not null,
  constraint fk_tree_element
    foreign key (tree_element_id)
    references tree_element(id),
  constraint fk_taxonomy_version_review_period
    foreign key (taxonomy_version_review_period_id)
    references taxonomy_version_review_period(id)
)
;
