ALTER TABLE taxonomy_reviewer ADD CONSTRAINT username_uniq UNIQUE (username);

ALTER TABLE tvr_periods_reviewers ADD CONSTRAINT period_reviewer_uniq UNIQUE (tvr_period_id, taxonomy_reviewer_id);
