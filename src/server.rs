use std::io::prelude::*;
use std::os::unix::fs::PermissionsExt;
use std::os::unix::net::{UnixListener, UnixStream};
use crate::configs::{Command, PIN_NUMBER, UNIX_SOCKET_PATH, TEMPERATRUE_FILENAME};
use rppal::gpio::Gpio;
use std::sync::{Mutex, Arc};
use std::{fs, thread, time::Duration, path::Path};
use chrono::prelude::*;
use bincode;

extern crate chrono;

struct Settings {
    low: u8,
    high: u8,
    pin: rppal::gpio::OutputPin,
}

pub fn serv(low: u8, high: u8, duration: u8) {

    let settings = Settings{
        low: low,
        high: high,
        pin: init_pin().unwrap(),
    };

    println!("fand: Temperature({}-{}) Pin: {} Duration: {} ", low, high, duration, PIN_NUMBER);
    
    let s = Arc::new(Mutex::new(settings));
    let sc = Arc::clone(&s);
    thread::spawn(move ||{
        monitor_temperature(duration, sc);
    });
    listen(s);
}

fn create_socket() -> UnixListener {
    let socket = Path::new(UNIX_SOCKET_PATH);
    if socket.exists() {
        fs::remove_file(socket).ok();
    }
    let listener = UnixListener::bind(&socket).unwrap();
    let mode = fs::Permissions::from_mode(0o666);
    fs::set_permissions(socket, mode).unwrap();
    return listener;
}

fn handle_client(mut stream: UnixStream, settings: &Arc<Mutex<Settings>>) {
    let mut buf = [0; 1024];
    let n = stream.read(&mut buf).unwrap();
    let cmd: Command = bincode::deserialize(&buf[..n]).unwrap();
    match cmd {
        Command::SetHigh(temp) => {
            let mut s = settings.lock().unwrap();
            s.high = temp;
        },
        Command::SetLow(temp) => {
            let mut s = settings.lock().unwrap();
            s.low = temp;
        },
        Command::On => set_pin(settings, true),
        Command::Off => set_pin(settings, false),
        Command::Show => {},
    }
    let resp = report(settings);
    stream.write(resp.as_bytes()).unwrap();
}

fn listen(settings: Arc<Mutex<Settings>>) {
    let listener = create_socket();
    for stream in listener.incoming(){
        let stream = stream.unwrap();
        handle_client(stream, &settings);
    }
}

fn get_low_high_temperature(settings: &Arc<Mutex<Settings>>) -> (u8, u8) {
    let s = settings.lock().unwrap();
    (s.low, s.high)
}

fn report(settings: &Arc<Mutex<Settings>>) -> String {
    let t = read_temperature();
    let dt = Local::now().format("%Y-%m-%d %H:%M:%S");

    let ps = get_pin(settings);
    let st = if ps { "on" } else { "off" };
   
    let (l, h) = get_low_high_temperature(settings);
    return format!("{dt} Temp({l}-{h}): {t} Pin({PIN_NUMBER}): {st}");
}

fn monitor_temperature(duration: u8, settings: Arc<Mutex<Settings>>) {
    loop{
        let (low, high) = get_low_high_temperature(&settings);
        let t = read_temperature();
        let ps = get_pin(&settings);

        if t > high && !ps{
            set_pin(&settings, true);
        }
        
        if t < low && ps{
            set_pin(&settings, false);
        }
        
        thread::sleep(Duration::from_secs(duration as u64));
    }
}

fn init_pin() -> Result<rppal::gpio::OutputPin, &'static str> {
    let a = Gpio::new();
    if let Ok(gpio) = a{
        let b = gpio.get(PIN_NUMBER);
        if let Ok(p) = b {
            let mut pin = p.into_output();
            pin.set_low();
            return Ok(pin);
        }
    }
    return Err("GPIO pin init failed!");
}

fn get_pin(settings: &Arc<Mutex<Settings>>) -> bool {
    let s = settings.lock().unwrap();
    s.pin.is_set_high()
}

fn set_pin(settings: &Arc<Mutex<Settings>>, is_high: bool) {
    let mut s = settings.lock().unwrap();
    if is_high{
        s.pin.set_high();
    }else{
        s.pin.set_low();
    }
}

fn read_temperature() -> u8{
    let content = fs::read_to_string(TEMPERATRUE_FILENAME);
    if let Ok(s) = content{
        let s = s.trim().parse::<u32>();
        if let Ok(t) = s{
            return (t / 1000) as u8;
        }
    }
    0u8
}
