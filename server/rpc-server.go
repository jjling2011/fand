package server

import (
	"context"
	"fmt"
	"rfan/comm/proto/rpc"

	"github.com/stianeikeland/go-rpio/v4"
)

type server struct {
	rpc.UnimplementedRpcServiceServer
}

func (s *server) TurnOn(ctx context.Context, in *rpc.Empty) (*rpc.Message, error) {
	writePin(uint8(settings.Pin), rpio.High)
	return defaultResp(), nil
}

func (s *server) TurnOff(ctx context.Context, in *rpc.Empty) (*rpc.Message, error) {
	writePin(uint8(settings.Pin), rpio.Low)
	return defaultResp(), nil
}

func (s *server) Report(ctx context.Context, in *rpc.Empty) (*rpc.Message, error) {
	return defaultResp(), nil
}

func defaultResp() *rpc.Message {
	curTemp := readCurTemp()
	pnum := uint8(settings.Pin)
	on := "Off"
	if readPin(pnum) == rpio.High {
		on = "On"
	}

	r := fmt.Sprintf(
		"Temp: %d (%d-%d) Port: %d Pin: %d (%s) Duration: %d",
		curTemp, settings.LowTemp, settings.HiTemp,
		settings.Port,
		settings.Pin,
		on,
		settings.Duration)

	return &rpc.Message{Body: r}
}
