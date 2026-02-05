env "local" {
  src = "file://db/schema/schema.sql"
  dev = getenv("CYCAS_ATLAS_DATABASE_URL")
  migration {
    dir    = "file://gen/db/migrations"
    format = golang-migrate
  }
  format {
    migrate {
      diff = "{{ sql . \"  \" }}"
    }
  }
}
