CREATE OR REPLACE VIEW hardrock_players_clean_v AS
WITH base AS (
  SELECT
    p.*,
    REGEXP_REPLACE(p.phone::text, '[^0-9]', '', 'g') AS phone_digits
  FROM hardrock_players p
)
SELECT
  player_id,
  TRIM(first_name) AS first_name,
  TRIM(last_name)  AS last_name,

  /* -------------------------
     Email cleanup (domain-safe)
     ------------------------- */
  CASE
    WHEN email IS NULL THEN NULL

    WHEN email NOT LIKE '%@%'
         AND LOWER(email) LIKE '%gmail.com'
    THEN REGEXP_REPLACE(LOWER(email), 'gmail\.com$', '@gmail.com')

    WHEN email NOT LIKE '%@%'
         AND LOWER(email) LIKE '%yahoo.com'
    THEN REGEXP_REPLACE(LOWER(email), 'yahoo\.com$', '@yahoo.com')

    WHEN email NOT LIKE '%@%'
         AND LOWER(email) LIKE '%outlook.com'
    THEN REGEXP_REPLACE(LOWER(email), 'outlook\.com$', '@outlook.com')

    WHEN email NOT LIKE '%@%'
         AND LOWER(email) LIKE '%icloud.com'
    THEN REGEXP_REPLACE(LOWER(email), 'icloud\.com$', '@icloud.com')

    ELSE email
  END AS email,

  /* -------------------------
     Phone cleanup
     ------------------------- */
  CASE
    WHEN phone_digits IS NULL THEN NULL

    -- 11-digit US number (assumes leading 1)
    WHEN LENGTH(phone_digits) = 11 AND LEFT(phone_digits, 1) = '1' THEN
      '+1-' ||
      SUBSTRING(phone_digits FROM 2 FOR 3) || '-' ||
      SUBSTRING(phone_digits FROM 5 FOR 3) || '-' ||
      SUBSTRING(phone_digits FROM 8 FOR 4)

    -- 10-digit US number
    WHEN LENGTH(phone_digits) = 10 THEN
      '+1-' ||
      SUBSTRING(phone_digits FROM 1 FOR 3) || '-' ||
      SUBSTRING(phone_digits FROM 4 FOR 3) || '-' ||
      SUBSTRING(phone_digits FROM 7 FOR 4)

    ELSE phone::text
  END AS phone,

  /* Address: treat blanks as NULL */
  NULLIF(TRIM(address), '') AS address,

  city,
  state,

  /* ZIP: strict CA validation */
  CASE
    WHEN state = 'CA' AND zip_code::text ~ '^9[0-9]{4}$'
    THEN zip_code::text
    ELSE NULL
  END AS zip_code,

  date_of_birth::date AS date_of_birth,

  /* Legal age flag */
  CASE
    WHEN date_of_birth IS NULL THEN FALSE
    WHEN date_of_birth::date > CURRENT_DATE THEN FALSE
    WHEN date_of_birth::date <= CURRENT_DATE - INTERVAL '21 years' THEN TRUE
    ELSE FALSE
  END AS is_legal_gambling_age,

  /* Signup date cleaned */
  CASE
    WHEN signup_date IS NULL THEN NULL
    WHEN signup_date::date > CURRENT_DATE THEN NULL
    WHEN signup_date::date < DATE '2015-01-01' THEN NULL
    WHEN date_of_birth IS NOT NULL
         AND signup_date::date < (date_of_birth::date + INTERVAL '21 years') THEN NULL
    WHEN last_visit_date IS NOT NULL
         AND signup_date::date > last_visit_date::date THEN NULL
    ELSE signup_date::date
  END AS signup_date_clean,

  tier_level,
  preferred_channel,
  active_flag,
  last_visit_date::date AS last_visit_date,
  lifetime_value

FROM base
WHERE
  -- Keep only legal-age players
  date_of_birth IS NOT NULL
  AND date_of_birth::date <= CURRENT_DATE - INTERVAL '21 years'

  -- Keep only rows with a VALID cleaned signup date
  AND (
    CASE
      WHEN signup_date IS NULL THEN NULL
      WHEN signup_date::date > CURRENT_DATE THEN NULL
      WHEN signup_date::date < DATE '2015-01-01' THEN NULL
      WHEN date_of_birth IS NOT NULL
           AND signup_date::date < (date_of_birth::date + INTERVAL '21 years') THEN NULL
      WHEN last_visit_date IS NOT NULL
           AND signup_date::date > last_visit_date::date THEN NULL
      ELSE signup_date::date
    END
  ) IS NOT NULL
;
