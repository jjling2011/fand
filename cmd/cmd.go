package cmd

import (
	"flag"
)

// Args of cmd
type Args struct {
	Duration   uint
	LowTemp    uint
	HiTemp     uint
	Pin        uint
	Port       uint
	ServerMode bool
	On         bool
	Off        bool
	Monitor    bool
}

// ParseFlags from cmd
func ParseFlags() *Args {
	var c = new(Args)

	flag.BoolVar(&c.ServerMode, "server", false, "Server mode.")
	flag.BoolVar(&c.On, "on", false, "Turn fan on.")
	flag.BoolVar(&c.Off, "off", false, "Turn fan off.")
	flag.BoolVar(&c.Monitor, "m", false, "Monitor mode")

	flag.UintVar(&c.Port, "port", 59246, "Listen on port.")
	flag.UintVar(&c.Duration, "duration", 60, "Check CPU temperature duration in seconds.")
	flag.UintVar(&c.Pin, "pin", 22, "BCM GPIO pin number.")
	flag.UintVar(&c.LowTemp, "low", 45, "Temperature to stop fan.")
	flag.UintVar(&c.HiTemp, "hi", 58, "Temperature to start fan.")
	flag.Parse()

	return c
}
