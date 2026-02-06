package main

import (
	"log"
	"os"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	_ "github.com/lib/pq"
)

func main() {
	databaseUrl := os.Getenv("CYCAS_DATABASE_URL")
	// TOOD: handle databaseUrl == "" case

	m, err := migrate.New("file://gen/db/migrations", databaseUrl)
	if err != nil {
		log.Fatal(err) // TODO: wrap error
	}
	defer m.Close() // TODO: check error

	if err = m.Up(); err != nil && err != migrate.ErrNoChange {
		log.Fatal(err) // TODO: wrap error
	}
}
