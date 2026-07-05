select regexp_replace(current_tve,'.*\/','') id,
       regexp_replace(regexp_replace(current_tve,'\/tree\/',''),'\/.*','') tv_id,
       simple_name,
       case operation
         when 'modified' then 'changed'
         else operation
       end,
       synonyms_html,
       name_path,
       current_tve,
       previous_tve,
51353484  tv_id_param
  from diff_list(51354547,51353484);
