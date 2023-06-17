import pandas as pd

# Parquet dosyasını oku
table = pd.read_parquet('light.parquet')

print(table)

columns = table.columns
print(columns)
