# Databricks notebook source
# MAGIC %run "../includes/configuration"

# COMMAND ----------

from pyspark.sql.types import StructType, StructField, StringType, DateType, DoubleType, LongType, IntegerType
from pyspark.sql.functions import col, regexp_replace, min as fmin, max as fmax

# COMMAND ----------

data_schema = StructType(
    [
        StructField("country", StringType(), True),
        StructField("indicator", StringType(), True),
        StructField("date", DateType(), True),
        StructField("year_week", StringType(), True),
        StructField("value", DoubleType(), True),
        StructField("source", StringType(), True),
        StructField("url", StringType(), True)
    ]
)

hospital_admissions_df = spark.read.csv(
    path=f'{raw_data_folder_path}/hospital_admissions.csv',
    schema=data_schema
)

# COMMAND ----------

# Split the file into daily and weekly data
daily_data_df = hospital_admissions_df.filter(hospital_admissions_df.indicator.startswith("Daily"))
weekly_data_df = hospital_admissions_df.filter(hospital_admissions_df.indicator.startswith("Weekly"))

# COMMAND ----------

# Pivot indicator column into 2 columns
daily_data_df = daily_data_df\
.groupby(['country', 'date', 'source'])\
.pivot('indicator', ['Daily hospital occupancy', 'Daily ICU occupancy'])\
.sum('value')

# COMMAND ----------

# Pivot indicator column into 2 columns
weekly_data_df = weekly_data_df\
.groupby(['country', 'year_week', 'source'])\
.pivot('indicator', ['Weekly new hospital admissions per 100k', 'Weekly new ICU admissions per 100k'])\
.sum('value')

# COMMAND ----------

# Load country info to enrich the hospital data
data_schema = StructType(
    [
        StructField("country", StringType(), True),
        StructField("country_code_2_digit", StringType(), True),
        StructField("country_code_3_digit", StringType(), True),
        StructField("continent", StringType(), True),
        StructField("population", LongType(), True)
    ]
)

country_info_df = spark.read.csv(
    path=f'{lookup_data_folder_path}/country_lookup.csv',
    schema=data_schema,
    header=True
)

# COMMAND ----------

# Data enriched using country info.
daily_data_df = daily_data_df.\
join(
    country_info_df,
    daily_data_df.country == country_info_df.country,
    'inner'
).\
select(
    daily_data_df.country,
    country_info_df.country_code_2_digit,
    country_info_df.country_code_3_digit,
    country_info_df.population,
    (daily_data_df.date).alias('reported_date'),
    col('Daily hospital occupancy').alias('hospital_occupancy_count'),
    col('Daily ICU occupancy').alias('icu_occupancy_count'),
    daily_data_df.source
)

# COMMAND ----------

daily_data_df.write.csv(
    path=f'{processed_data_folder_path}/daily_data',
    mode='overwrite',
    header=True
)

# COMMAND ----------

data_schema = StructType(
    [
        StructField('date_key', StringType(), True),
        StructField('date', DateType(), True),
        StructField('year', IntegerType(), True),
        StructField('month', IntegerType(), True),
        StructField('day', IntegerType(), True),
        StructField('day_name', StringType(), True),
        StructField('day_of_year', IntegerType(), True),
        StructField('week_of_month', IntegerType(), True),
        StructField('week_of_year', IntegerType(), True),
        StructField('month_name', StringType(), True),
        StructField('year_month', StringType(), True),
        StructField('year_week', StringType(), True)
    ]
)

dates_data_df = spark.read.csv(
    path=f'{lookup_data_folder_path}/dim_date.csv',
    schema=data_schema,
    header=True
)

# COMMAND ----------

weekly_data_df = weekly_data_df.withColumn('reported_year_week',regexp_replace('year_week', '-W', ''))

# COMMAND ----------

grouped_dates_df = dates_data_df.groupby('year_week').agg(fmin('date').alias('start_date'), fmax('date').alias('end_date'))

# COMMAND ----------

weekly_data_df = weekly_data_df\
.join(
    grouped_dates_df,
    weekly_data_df.reported_year_week == grouped_dates_df.year_week,
    'left'
)\
.select(
    weekly_data_df.country,
    weekly_data_df.reported_year_week,
    (grouped_dates_df.start_date).alias('reported_week_start_date'),
    (grouped_dates_df.end_date).alias('reported_week_end_date'),
    col('Weekly new hospital admissions per 100k').alias('new_hospital_occupancy_count'),
    col('Weekly new ICU admissions per 100k').alias('new_icu_occupancy_count'),
    weekly_data_df.source
)

# COMMAND ----------

weekly_data_df = weekly_data_df\
.join(
    country_info_df,
    weekly_data_df.country == country_info_df.country,
    'left'
)\
.select(
    weekly_data_df.country,
    country_info_df.country_code_2_digit,
    country_info_df.country_code_3_digit,
    country_info_df.population,
    weekly_data_df.reported_year_week,
    weekly_data_df.reported_week_start_date,
    weekly_data_df.reported_week_end_date,
    weekly_data_df.new_hospital_occupancy_count,
    weekly_data_df.new_icu_occupancy_count,
    weekly_data_df.source
)

# COMMAND ----------

weekly_data_df.write.csv(
    path=f'{processed_data_folder_path}/weekly_data',
    mode='overwrite',
    header=True
)

# COMMAND ----------


