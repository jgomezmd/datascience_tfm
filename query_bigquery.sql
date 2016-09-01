SELECT
  Actor1CountryCode,
  Actor2CountryCode,
  AvgTone,
  NumArticles,
  SQLDATE,
  Year,
  Actor1Geo_Lat,
  Actor1Geo_Long,
  ActionGeo_CountryCode,
  EventCode,
  EventRootCode,
  Actor1Geo_CountryCode,
  Actor2Geo_CountryCode,
  SOURCEURL
FROM
  [gdelt-bq.full.events]
WHERE
  ActionGeo_CountryCode == 'SY'
  AND Year >= 2011
  AND (EventCode IN ('0233',
      '0234',
      '0256',
      '0333',
      '0334',
      '0356',
      '073',
      '074',
      '1033',
      '1034',
      '1056')
    OR EventRootCode IN ('18',
      '19',
      '20'));
