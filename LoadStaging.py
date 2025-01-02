import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy.exc import SQLAlchemyError

external_server = 'ACER'
external_database = 'externalDB2'
internal_server = 'ACER'
internal_database = 'internalDB2'

external_connection_string = f'mssql+pyodbc://@{external_server}/{external_database}?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes'
internal_connection_string = f'mssql+pyodbc://@{internal_server}/{internal_database}?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes'

try:
    external_engine = create_engine(external_connection_string)
    internal_engine = create_engine(internal_connection_string)
    print("Successfully connected to both databases.")
except SQLAlchemyError as e:
    print(f"Error connecting to the database: {e}")
    exit(1)

def extract_and_load(table_name):
    try:
        external_query = f'SELECT * FROM externalDWH.{table_name}'
        df = pd.read_sql_query(external_query, con=external_engine)
        df.to_sql(f'{table_name}', con=internal_engine, schema='Staging', if_exists='replace', index=False)
        print(f'Data from externalDWH.{table_name} loaded into Staging.{table_name}')
    except SQLAlchemyError as e:
        print(f"Error processing table {table_name}: {e}")

tables = ['Sale', 'Transactions', 'Inventory', 'Customer', 'Date', 'Region']

def main():
    for table in tables:
        extract_and_load(table)

if __name__ == "__main__":
    main()