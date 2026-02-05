package main

import (
	"log"

	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	_ "github.com/lib/pq"

	"codeberg.org/bashar-515/cycas/internal/config"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatal(err)
	}

	m, err := migrate.New("file://gen/db/migrations", cfg.DatabaseUrl)
	if err != nil {
		log.Fatal(err) // TODO: wrap error
	}
	defer m.Close() // TODO: check error

	if err = m.Up(); err != nil && err != migrate.ErrNoChange {
		log.Fatal(err) // TODO: wrap error
	}
}
