create table tvr_period_tve_comment (
  id bigint primary key default nextval('nsl_global_seq'::regclass),
  tree_version_element_link text not null,
  tvr_period_id bigint not null,
  taxonomy_reviewer_id bigint not null,
  comment text not null,
  lock_version bigint not null default 0,
  created_at timestamp with time zone not null,
  created_by character varying(50)    not null,
  updated_at timestamp with time zone not null,
  updated_by character varying(50)    not null,
  constraint fk_tree_version_element_link
    foreign key (tree_version_element_link)
    references tree_version_element(element_link),
  constraint fk_taxonomy_version_review_period
    foreign key (tvr_period_id)
    references taxonomy_version_review_period(id),
  constraint fk_taxonomy_reviewer
    foreign key (taxonomy_reviewer_id)
    references taxonomy_reviewer(id)
)
;
