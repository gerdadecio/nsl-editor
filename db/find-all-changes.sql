drop function find_all_changes(v1 bigint, v2 bigint);

create function find_all_changes(v1 bigint, v2 bigint)
    returns table (te_id bigint, simple_name varchar, previous_element_id bigint, synonyms jsonb, synonyms_html text, operation varchar, tree_version_id bigint)
    language sql
as
$$

select id, simple_name, previous_element_id, synonyms, synonyms_html, 'added' op, v1 from tree_element
where previous_element_id is null
  and id in
(
SELECT tree_element_id
   FROM tree_version_element
   WHERE tree_version_id = v1 
  EXCEPT
  SELECT tree_element_id
   FROM tree_version_element
   WHERE tree_version_id = v2
)
union
select id, simple_name, previous_element_id, synonyms, synonyms_html, 'removed' op, v1 from tree_element
where previous_element_id is null
  and id in
(
SELECT tree_element_id
   FROM tree_version_element
   WHERE tree_version_id = v2
  EXCEPT
  SELECT tree_element_id
   FROM tree_version_element
   WHERE tree_version_id = v1 
)
union
select id, simple_name, previous_element_id, synonyms, synonyms_html, 'changed' op, v1 from tree_element
where previous_element_id is not null
  and id in
(
SELECT tree_element_id
   FROM tree_version_element
   WHERE tree_version_id = v1 
  EXCEPT
  SELECT tree_element_id
   FROM tree_version_element
   WHERE tree_version_id = v2
)
$$
;

