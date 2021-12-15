select case coalesce(name_status,'empty') when 'empty' then 'no name status' else 'has name status' end ns, case taxon = taxon_full when true then 'no authors supplied' else 'authors supplied' end "authors supplied in full name?", count(*) from loader_batch_raw_list_2019_with_taxon_full group by case coalesce(name_status,'empty') when 'empty' then 'no name status' else 'has name status' end, case taxon = taxon_full when true then 'no authors supplied' else 'authors supplied' end order by 1,2,3;