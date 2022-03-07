use std::io::prelude::*;
use std::{thread, time::Duration, path::Path};
use std::os::unix::net::UnixStream;
use crate::configs::{Command, UNIX_SOCKET_PATH};

pub fn on(){
    let cmd = Command::On;
    send_cmd(cmd);
}

pub fn off(){
    let cmd = Command::Off;
    send_cmd(cmd);
}

pub fn set_high(temp: u8) {
    let cmd = Command::SetHigh(temp);
    send_cmd(cmd);
}

pub fn set_low(temp: u8) {
    let cmd = Command::SetLow(temp);
    send_cmd(cmd);
}

pub fn show() {
    let cmd = Command::Show;
    send_cmd(cmd);
}

pub fn mon(duration: u8) {
    loop{
        show();
        thread::sleep(Duration::from_secs(duration as u64));
    }
}

fn send_cmd(cmd: Command) {
    let mut stream = connect();
    let cmd: Vec<u8> = bincode::serialize(&cmd).unwrap();
    stream.write(&cmd).unwrap();
    let resp = read_resp(&mut stream);
    println!("{resp}");
}

fn read_resp(stream: &mut UnixStream) -> String {
    let mut buf = [0; 1024];
    let n = stream.read(&mut buf).unwrap();
    let resp = String::from_utf8_lossy(&buf[..n]).into_owned();
    resp
}

fn connect() -> UnixStream {
    let p = Path::new(UNIX_SOCKET_PATH);
    let socket = UnixStream::connect(p).unwrap();
    socket
}