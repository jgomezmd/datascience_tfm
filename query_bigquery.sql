SELECT
  *
FROM
  [gdelt-bq.full.events]
WHERE
  ActionGeo_CountryCode == 'SY'
  AND Year >= 2011
;
