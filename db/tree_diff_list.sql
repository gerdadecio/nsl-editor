drop function if exists not_in(v1 bigint, v2 bigint);
create function not_in(v1 bigint, v2 bigint)
    returns table
            (
                element_link    text,
                tree_element_id bigint
            )
    language sql
as
$$
Select t1.element_link, t1.tree_element_id
from (SELECT * FROM tree_version_element WHERE tree_version_id = v1) t1
where t1.tree_element_id not in (SELECT t2.tree_element_id FROM tree_version_element t2 WHERE tree_version_id = v2)
$$;

drop function if exists find_modified(v1 bigint, v2 bigint);
create function find_modified(v1 bigint, v2 bigint)
    returns table
            (
                tve_element_link  text,
                tve_te_id bigint,
                ptve_element_link text,
                ptve_te_id bigint
            )
    language sql
as
$$
select tve.element_link, tve.tree_element_id, ptve.element_link, ptve.tree_element_id
from Tree_Version_Element tve
         join tree_element te on tve.tree_element_id = te.id
        , Tree_Version_Element ptve
              join tree_element pte on ptve.tree_element_id = pte.id,
     not_in(v1,v2) not_in_first
where tve.tree_version_id = v1
  and ptve.tree_version_id = v2
  and pte.name_id = te.name_id
  and te.id in (not_in_first.tree_element_id)
order by tve.name_path
$$;

drop function if exists find_removed(v1 bigint, v2 bigint);
create function find_removed(v1 bigint, v2 bigint)
    returns table
            (
                ptve_element_link text,
                ptve_te_id bigint
            )
    language sql
as
$$
select not_in_first.element_link, not_in_first.tree_element_id
from not_in(v1,v2) not_in_first
where
        not_in_first.tree_element_id not in (select tve_te_id from find_modified(v1, v2))
$$;

drop function if exists find_added(v1 bigint, v2 bigint);
create function find_added(v1 bigint, v2 bigint)
    returns table
            (
                tve_element_link  text,
                tve_te_id         bigint
            )
    language sql
as
$$
select not_in_first.element_link, not_in_first.tree_element_id
from not_in(v2, v1) not_in_first
where not_in_first.tree_element_id not in (select ptve_te_id from find_modified(v1, v2))
$$;

drop function if exists diff_list(v1 bigint, v2 bigint);
create function diff_list(v1 bigint, v2 bigint)
    returns table(
                     operation text,
                     previous_tve text,
                     current_tve text,
                     simple_name text,
                     synonyms_html text,
                     name_path text
                 )
    language sql
as
$$
select 'modified' op, ptve_element_link, after.element_link, after_te.simple_name, after_te.synonyms_html, after.name_path
from find_modified(v1, v2)
         join tree_version_element after on tve_element_link = after.element_link
         join tree_element after_te on after.tree_element_id = after_te.id
union
select 'added' op, ''::text, after.element_link, after_te.simple_name, after_te.synonyms_html, after.name_path
from find_added(v1, v2)
         join tree_version_element after on tve_element_link = after.element_link
         join tree_element after_te on after.tree_element_id = after_te.id
union
select  'removed' op, ptve_element_link, ''::text, before_te.simple_name, before_te.synonyms_html, before.name_path
from find_removed(v1, v2)
         join tree_version_element before on ptve_element_link = before.element_link
         join tree_element before_te on before.tree_element_id = before_te.id
order by name_path
$$
;
