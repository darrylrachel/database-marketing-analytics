CREATE OR REPLACE VIEW hardrock_players_rejected_v AS
WITH base AS (
  SELECT
    p.*,
    REGEXP_REPLACE(p.phone::text, '[^0-9]', '', 'g') AS phone_digits
  FROM hardrock_players p
)
SELECT
  player_id,
  first_name,
  last_name,
  email,
  phone,
  address,
  city,
  state,
  zip_code,
  date_of_birth,
  signup_date,
  last_visit_date,
  tier_level,
  preferred_channel,
  active_flag,
  lifetime_value,

  /* -------------------------
     Rejection reason (1 primary)
     ------------------------- */
  CASE
    /* DOB / age issues */
    WHEN date_of_birth IS NULL
      THEN 'missing_date_of_birth'

    WHEN date_of_birth::date > CURRENT_DATE
      THEN 'date_of_birth_in_future'

    WHEN date_of_birth::date > CURRENT_DATE - INTERVAL '21 years'
      THEN 'underage_player'

    /* Signup date issues */
    WHEN signup_date IS NULL
      THEN 'missing_signup_date'

    WHEN signup_date::date > CURRENT_DATE
      THEN 'signup_date_in_future'

    WHEN signup_date::date < DATE '2015-01-01'
      THEN 'signup_date_too_old'

    WHEN date_of_birth IS NOT NULL
         AND signup_date::date < (date_of_birth::date + INTERVAL '21 years')
      THEN 'signup_before_legal_age'

    WHEN last_visit_date IS NOT NULL
         AND signup_date::date > last_visit_date::date
      THEN 'signup_after_last_visit'

    /* Catch-all (should be rare) */
    ELSE 'other_data_quality_issue'
  END AS rejection_reason

FROM base
WHERE
  /* Anything that fails the clean-table criteria */
  date_of_birth IS NULL
  OR date_of_birth::date > CURRENT_DATE
  OR date_of_birth::date > CURRENT_DATE - INTERVAL '21 years'
  OR signup_date IS NULL
  OR signup_date::date > CURRENT_DATE
  OR signup_date::date < DATE '2015-01-01'
  OR (
       date_of_birth IS NOT NULL
       AND signup_date::date < (date_of_birth::date + INTERVAL '21 years')
     )
  OR (
       last_visit_date IS NOT NULL
       AND signup_date::date > last_visit_date::date
     )
;
