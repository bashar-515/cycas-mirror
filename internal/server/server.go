package server

import (
	"context"

	"codeberg.org/bashar-515/cycas/gen/api"
)

type Server struct{}

func NewServer() api.StrictServerInterface {
	return &Server{}
}

func (s *Server) Ping(ctx context.Context, request api.PingRequestObject) (api.PingResponseObject, error) {
	return api.Ping200TextResponse("pong"), nil
}

func (s *Server) CreateCategory(ctx context.Context, request api.CreateCategoryRequestObject) (api.CreateCategoryResponseObject, error) {
	return nil, nil
}
