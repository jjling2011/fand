package server

import (
	"fmt"
	"log"
	"net"
	"rfan/cmd"
	"rfan/comm/proto/rpc"
	"time"

	"github.com/stianeikeland/go-rpio/v4"
	"google.golang.org/grpc"
)

var (
	settings *cmd.Args
)

// Run run run
func Run(args *cmd.Args) {
	if err := rpio.Open(); err != nil {
		log.Println("Open GPIO pin failed!")
		return
	}
	settings = args
	log.Printf("Fand is running in server mode. %s", defaultResp().Body)
	go startDaemon(args)
	startRPCServer(args)
}

func startDaemon(args *cmd.Args) {
	pn := uint8(args.Pin)
	d := time.Duration(settings.Duration) * time.Second

	for {
		curT := readCurTemp()
		curS := readPin(pn)
		if curT > args.HiTemp && curS != rpio.High {
			writePin(pn, rpio.High)
		} else if curT < args.LowTemp && curS != rpio.Low {
			writePin(pn, rpio.Low)
		}
		time.Sleep(d)
	}
}

func startRPCServer(args *cmd.Args) {
	addr := fmt.Sprintf("localhost:%d", args.Port)
	tServ, err := net.Listen("tcp", addr)
	if err != nil {
		log.Fatalf("Fail to listen: %v", err)
		return
	}

	gServ := grpc.NewServer()
	rpc.RegisterRpcServiceServer(gServ, &server{})

	if err := gServ.Serve(tServ); err != nil {
		log.Fatalf("failed to create GRPC service: %s", err)
	}
}
