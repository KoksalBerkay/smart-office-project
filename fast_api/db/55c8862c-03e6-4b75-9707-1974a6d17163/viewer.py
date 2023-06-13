import pyarrow.parquet as pq

# Parquet dosyasını oku
table = pq.read_table('light.parquet')

print(table.to_pandas())

columns = table.schema.names
print(columns)
