package client

import (
	"context"
	"fmt"
	"log"
	"time"

	"rfan/cmd"
	pb "rfan/comm/proto/rpc"

	"google.golang.org/grpc"
)

var (
	empty = &pb.Empty{}
)

func query(c pb.RpcServiceClient, args *cmd.Args) {
	ctx := context.Background()
	var r *pb.Message
	var err error

	if args.Monitor {
		for {
			r, err = c.Report(ctx, empty)
			if err != nil {
				log.Fatalf("GRPC error: %v", err)
				return
			}
			log.Printf("%s", r.Body)
			time.Sleep(3 * time.Second)
		}
	}

	if args.On {
		r, err = c.TurnOn(ctx, empty)
	} else if args.Off {
		r, err = c.TurnOff(ctx, empty)
	} else {
		r, err = c.Report(ctx, empty)
	}
	if err != nil {
		log.Fatalf("could not greet: %v", err)
	}
	log.Printf("%s", r.Body)
}

// Run run run
func Run(args *cmd.Args) {
	addr := fmt.Sprintf("localhost:%d", args.Port)
	conn, err := grpc.Dial(addr, grpc.WithInsecure(), grpc.WithBlock())
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()

	client := pb.NewRpcServiceClient(conn)
	query(client, args)
}
