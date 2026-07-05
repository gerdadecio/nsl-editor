create table taxonomy_version_review_period (
  id bigint primary key default nextval('nsl_global_seq'::regclass),
  taxonomy_version_review_id bigint not null,
  start_date date not null,
  end_date date,
  lock_version bigint not null default 0,
  created_at timestamp with time zone not null,
  created_by character varying(50)    not null,
  updated_at timestamp with time zone not null,
  updated_by character varying(50)    not null,
  constraint fk_taxonomy_review
    foreign key (taxonomy_version_review_id)
    references taxonomy_version_review(id)
)
;
