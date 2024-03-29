-- 1. Download GeoIP City and GeoIP Country files from maxmind: https://www.maxmind.com/en/accounts/current/geoip/downloads  (creds in lastpass)
-- 2. Download geoip2-csv-converter to convert the downloaded files from #1 https://github.com/maxmind/geoip2-csv-converter/releases
-- 3. Run the converter from #2 to get the data with integer and string ranges using the IPv4 files:

-- From local
time ./geoip2-csv-converter \
-block-file ../GeoIP2-City-CSV_20181009/GeoIP2-City-Blocks-IPv4.csv \
-include-cidr \
-include-integer-range  \
-include-range  \
-output-file ip_location.out.csv

-- 4. Load the city_ip_location and country_ip_location from output in #3
-- a. create table ddl in snowflake

create table db.geo_ip.ip_location
( network                        varchar(16777216)
, network_start_ip               varchar(16777216)
, network_last_ip                varchar(16777216)
, network_start_integer          number(38,0)
, network_last_integer           number(38,0)
, geoname_id                     number(38,0)
, registered_country_geoname_id  number(38,0)
, represented_country_geoname_id number(38,0)
, is_anonymous_proxy             boolean
, is_satellite_provider          boolean
, postal_code                    varchar(16777216)
, latitude                       number(38,0)
, longitude                      number(38,0)
, accuracy_radius                number(38,0)
)
;

-- b. stage the table:
put file:///the_path_to_the_file/ip_location.out.csv @%ip_location;

/* output:
ip_location.out.csv_c.gz(163.63MB): [##########] 100.00% Done (13.245s, 12.35MB/s).
+---------------------+------------------------+-------------+-------------+--------------------+--------------------+----------+---------+
| source              | target                 | source_size | target_size | source_compression | target_compression | status   | message |
|---------------------+------------------------+-------------+-------------+--------------------+--------------------+----------+---------|
| ip_location.out.csv | ip_location.out.csv.gz |   913689083 |   171581063 | NONE               | GZIP               | UPLOADED |         |
+---------------------+------------------------+-------------+-------------+--------------------+--------------------+----------+---------+
*/

-- confirm the table is staged
list @%ip_location;

/* output:
+------------------------+-----------+-------------------------------------+-------------------------------+
| name                   |      size | md5                                 | last_modified                 |
|------------------------+-----------+-------------------------------------+-------------------------------|
| ip_location.out.csv.gz | 171581072 | e11e6d0238939fbd4faf33704c820b0c-21 | Thu, 11 Oct 2018 17:16:42 GMT |
+------------------------+-----------+-------------------------------------+-------------------------------+
*/

copy into ip_location file_format = (type = csv field_delimiter = ',' FIELD_OPTIONALLY_ENCLOSED_BY = '"' skip_header = 1);
/* output:
+------------------------+--------+-------------+-------------+-------------+-------------+-------------+------------------+-----------------------+-------------------------+
| file                   | status | rows_parsed | rows_loaded | error_limit | errors_seen | first_error | first_error_line | first_error_character | first_error_column_name |
|------------------------+--------+-------------+-------------+-------------+-------------+-------------+------------------+-----------------------+-------------------------|
| ip_location.out.csv.gz | LOADED |     8157075 |     8157075 |           1 |           0 | NULL        |             NULL |                  NULL | NULL                    |
+------------------------+--------+-------------+-------------+-------------+-------------+-------------+------------------+-----------------------+-------------------------+
*/

select count(1) from db.geo_ip.ip_location;
/* output:
+----------+
| COUNT(1) |
|----------|
|  8157075 |
+----------+
*/

-- 6. cleanup stage tables
remove @%ip_location;
