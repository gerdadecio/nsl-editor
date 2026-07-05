create table taxonomy_reviewer (
  id bigint primary key default nextval('nsl_global_seq'::regclass),
  username varchar(30) not null,
  organisation_name varchar(50) not null,
  role_name varchar(30) not null,
  active boolean not null default true,
  lock_version bigint not null default 0,
  created_at timestamp with time zone not null,
  created_by character varying(50)    not null,
  updated_at timestamp with time zone not null,
  updated_by character varying(50)    not null
)
;
