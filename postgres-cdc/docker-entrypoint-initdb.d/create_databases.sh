# psql -U $POSTGRES_USER $POSTGRES_DB -tc "SELECT 1 FROM pg_database WHERE datname = 'appl_tracky_database'" | grep -q 1 || psql -U $POSTGRES_USER $POSTGRES_DB -c "CREATE DATABASE appl_tracky_database"

# psql -U $POSTGRES_USER $POSTGRES_DB -tc "SELECT 1 FROM pg_database WHERE datname = 'iriversland2_database'" | grep -q 1 || psql -U $POSTGRES_USER $POSTGRES_DB -c "CREATE DATABASE iriversland2_database"

# testing in psql
# \list --> list databases
# \c database_name --> choose active database
# \dt shows all table in that database

# creating test table
# CREATE TABLE test_new (
#     id int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY, -- enable auto increment
# );