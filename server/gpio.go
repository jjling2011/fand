package server

import (
	"io/ioutil"
	"log"
	"regexp"
	"strconv"

	"github.com/stianeikeland/go-rpio/v4"
)

func readNumber(file string) uint {

	buf, err := ioutil.ReadFile(file)
	if err != nil {
		log.Println("read file error")
		return 0
	}

	re := regexp.MustCompile("[0-9]+")
	s := string(re.Find(buf))
	t, err := strconv.Atoi(s)
	if err != nil {
		log.Printf("Parse temp fail: [%s]", s)
		return 0
	}
	return uint(t)
}

func readCurTemp() uint {
	path := "/sys/class/thermal/thermal_zone0/temp"
	return uint(readNumber(path) / 1000)
}

func readPin(num uint8) rpio.State {
	pin := rpio.Pin(num)
	st := pin.Read()
	return st
}

func writePin(num uint8, state rpio.State) {
	pin := rpio.Pin(num)
	pin.Output()
	if state == rpio.High {
		pin.High()
	} else {
		pin.Low()
	}
}
