#!/usr/bin/bash

cd comm/proto
protoc --go_out=plugins=grpc:rpc rpc.proto