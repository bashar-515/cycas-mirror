package main

import (
	"context"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	nethttpmiddleware "github.com/oapi-codegen/nethttp-middleware"

	"codeberg.org/bashar-515/cycas/gen/api"
	"codeberg.org/bashar-515/cycas/internal/server"
)

const port = ":9000"

func main() {
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()

	swagger, err := api.GetSwagger()
	if err != nil {
		log.Fatal(err) // TODO: wrap error
	}

	srv := &http.Server{
		Handler: nethttpmiddleware.OapiRequestValidatorWithOptions(
			swagger,
			&nethttpmiddleware.Options{SilenceServersWarning: true},
		)(
			api.Handler(api.NewStrictHandler(server.NewServer(), []api.StrictMiddlewareFunc{})),
		),
	}

	listener, err := net.Listen("tcp", port)
	if err != nil {
		log.Fatal(err) // TODO: wrap error
	}

	log.Printf("starting Cycas API server on port %s", port)

	go func() {
		if err := srv.Serve(listener); err != nil && err != http.ErrServerClosed {
			log.Fatalf("error listening and serving: %v", err) // TODO: stop calling log.Fatalf in this Go routine
		}
	}()

	<-ctx.Done()

	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer shutdownCancel()

	if err = srv.Shutdown(shutdownCtx); err != nil {
		log.Fatalf("error shutting server down: %v", err)
	}
}
