# TFM Master Data Science
## Javier Gomez Maqueda

Utilizamos datos de GDELT para observar la evolución de los artículos sobre ayuda, intentos de ayuda y lucha en Siria. Procesamos la información para reducirla con SPARK y trabajamos los datos con Rshiny.

### Local
1. Lanzar spider.py "python spider.py range -y 2011-2016 -d /home/javi/masterdatascience/TFM/pruebas/gdelt/ -U"
2. Procesar la información con el programa data_process_gdelt.ipynb "$SPARK_HOME/bin/pyspark" **Ojo es SPARK 2.0.0**
3. Lanzar desde R la app "runApp("syria")"

### BigQuery
1. Lanzar la consulta query_bigquery.sql en google BigQuery => data_for_github
2. Lanzar la aplicación explore_series_shiny.R
