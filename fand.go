package main

import (
	"rfan/client"
	"rfan/cmd"
	"rfan/server"
)

func main() {
	args := cmd.ParseFlags()
	// fmt.Printf("Args: %v\n", args)
	if args.ServerMode {
		server.Run(args)
	} else {
		client.Run(args)
	}
}
