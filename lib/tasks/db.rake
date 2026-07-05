#
# this is the command I used to test these scripts
#
# dropdb ned_test; createdb -O nsl ned_test; bundle exec rake db:schema:dump; bundle exec rake db:clean_up_structure_sql; RAILS_ENV=test bin/rails db:setup
#
#
#

# Rails 8 passes --set ON_ERROR_STOP=1 to psql by default, which aborts the
# structure.sql load on the first error.  Override to remove that flag so psql
# continues past errors and loads as much of the schema as possible.
module ActiveRecord
  module Tasks
    class PostgreSQLDatabaseTasks
      def structure_load(filename, extra_flags)
        # Create required extensions before loading the schema.
        # Done here (not via a rake hook) so it fires on every code path —
        # including when Rails auto-maintains the test database on a single
        # test run, which uses the Ruby API rather than rake tasks.
        Kernel.system(psql_env, "psql", "--quiet", "--no-psqlrc",
                      "--output", File::NULL,
                      "-c", "CREATE EXTENSION IF NOT EXISTS pg_trgm; CREATE EXTENSION IF NOT EXISTS unaccent;",
                      db_config.database)

        # Identical to Rails 8.1 default but without --set ON_ERROR_STOP=1,
        # so psql continues past errors instead of aborting on the first one.
        args = ["--quiet", "--no-psqlrc", "--output", File::NULL]
        args.concat(Array(extra_flags)) if extra_flags
        args.concat(["--file", filename])
        args << db_config.database
        run_cmd("psql", *args)
      end
    end
  end
end
namespace :db do
  desc "Clean up the structure.sql file (Ruby version) - run this after you generate structure.sql"
  task clean_up_structure_sql_ruby: :environment do
    path = "db/structure.sql"
    sql  = File.read(path)

    # a — remove CREATE SCHEMA public (already exists in target db)
    sql.gsub!(/^CREATE SCHEMA public;\n/, "")

    # b — remove get_hstore_tree function
    sql.gsub!(
      /^CREATE FUNCTION public\.get_hstore_tree.tve_id text. RETURNS public\.hstore.*?RETURN result_hstore;\n[^\n]*\n[^\n]*\n/m,
      ""
    )

    # c — remove taxon_mv materialized view definition
    sql.gsub!(/^CREATE MATERIALIZED VIEW public\.taxon_mv AS.*?WITH NO DATA;\n/m, "")

    # c1 — remove COMMENT ON MATERIALIZED VIEW public.taxon_mv lines
    sql.gsub!(/^COMMENT ON MATERIALIZED VIEW public\.taxon_mv[^\n]*\n/, "")

    # c2 — remove COMMENT ON COLUMN public.taxon_mv.* lines
    sql.gsub!(/^COMMENT ON COLUMN public\.taxon_mv\.[^\n]*\n/, "")

    # d — remove tnu_index_v view (depends on objects not in this schema)
    sql.gsub!(/^CREATE VIEW public\.tnu_index_v AS.*?ORDER BY[^\n]*\n/m, "")

    # e — remove gettnu function (depends on tnu_index_v)
    sql.gsub!(
      /^CREATE FUNCTION public\.gettnu.tnu_name text. RETURNS SETOF public\.tnu_index_v.*?name_published_in_year;\n[^\n]*\n[^\n]*\n/m,
      ""
    )

    # f — remove trees_mv materialized view definition
    sql.gsub!(/^CREATE MATERIALIZED VIEW public\.trees_mv AS.*?WITH NO DATA;\n/m, "")

    # g, h, i, j, k, l — remove views (delete to next blank line)
    %w[taxon_v nsl_tree_mv cited_usage_v taxon_name_usage_v taxonomic_status_v tree_closure_v].each do |view|
      sql.gsub!(/^CREATE VIEW public\.#{view} AS.*?\n[ \t]*\n/m, "")
    end

    # m — remove single-line CREATE statements referencing trees_mv and taxon_mv indexes,
    #     and the COMMENT ON VIEW public.taxon_view line
    sql.gsub!(/^CREATE [^\n]*trees_mv[^\n]*;\n/, "")
    sql.gsub!(/^CREATE [^\n]*taxon_mv[^\n]*;\n/, "")
    sql.gsub!(/^COMMENT ON VIEW public\.taxon_view IS [^\n]*;\n/, "")

    # n, o, p, q, r, s, t, v, w — remove more views (delete to next blank line)
    %w[bdr_alt_labels_v bdr_concept_v bdr_top_concept_v bdr_unplaced_v
       current_scheme_v dist_granular_booleans_v dwc_taxon_v nsl_taxon_cv nsl_tree_closure_cv].each do |view|
      sql.gsub!(/^CREATE VIEW public\.#{view} AS.*?\n[ \t]*\n/m, "")
    end

    # u — remove COMMENT ON VIEW public.dwc_taxon_v
    sql.gsub!(/^COMMENT ON VIEW public\.dwc_taxon_v IS [^\n]*;\n/, "")

    # x — remove taxon_mv_compare table
    sql.gsub!(/^CREATE TABLE public\.taxon_mv_compare.*?\n[ \t]*\n/m, "")

    # y — remove taxon_view
    sql.gsub!(/^CREATE VIEW public\.taxon_view AS.*?\n[ \t]*\n/m, "")

    # z — remove name_mv materialized view
    sql.gsub!(/^CREATE MATERIALIZED VIEW public\.name_mv AS.*?\n[ \t]*\n/m, "")

    # z1 — remove taxon_name_v view
    sql.gsub!(/^CREATE VIEW public\.taxon_name_v AS.*?\n[ \t]*\n/m, "")

    # z2 — remove all remaining COMMENT ON lines
    sql.gsub!(/^COMMENT ON [^\n]*;\n/, "")

    # z3, z4, z5 — remove more views
    sql.gsub!(/^CREATE VIEW public\.dwc_name_v AS.*?\n[ \t]*\n/m, "")
    sql.gsub!(/^CREATE VIEW public\.name_view AS.*?\n[ \t]*\n/m, "")
    sql.gsub!(/^CREATE VIEW public\.wfo_export AS.*?\n[ \t]*\n/m, "")

    # remove foreign tables (reference servers that don't exist in test/dev environments)
    sql.gsub!(/^CREATE FOREIGN TABLE public\.apii_image_profile.*?;\n/m, "")

    # z6 — omitted: pg_dump now exports extensions and f_unaccent directly,
    #      and structure_load creates extensions before every schema load.

    # z7 — remove index/constraint statements on name_mv and audit triggers
    sql.gsub!(/^CREATE [^\n]* ON public\.name_mv[^\n]*;\n/, "")
    sql.gsub!(/^CREATE TRIGGER audit[^\n]*;\n/, "")

    # z8 — add CREATE SCHEMA audit after CREATE SCHEMA loader
    sql.gsub!(/^(CREATE SCHEMA loader;)$/, "\\1\nCREATE SCHEMA audit;")

    # z9 — remove sequence range constraints
    sql.gsub!(/^[^\n]*START WITH 50000001[^\n]*\n/, "")
    sql.gsub!(/^[^\n]*MINVALUE 50000001[^\n]*\n/, "")
    sql.gsub!(/^[^\n]*MAXVALUE 60000000[^\n]*\n/, "")

    # z9a — add loader sequence definition after CREATE SCHEMA loader
    loader_sequence = "CREATE SEQUENCE loader.nsl_global_seq\n    INCREMENT BY 1\n    CACHE 1;\n\n"
    sql.gsub!(/^(CREATE SCHEMA loader;)/, "\\1\n#{loader_sequence}")

    # z9b — remove nsl_name_rank materialized view
    sql.gsub!(/^CREATE MATERIALIZED VIEW public\.nsl_name_rank AS.*?\n[ \t]*\n/m, "")

    File.write(path, sql)
    puts "db/structure.sql cleaned up"
  end

  desc "Create required PostgreSQL extensions in the current database"
  task create_extensions: :environment do
    ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")
    ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS unaccent")
  end
end



