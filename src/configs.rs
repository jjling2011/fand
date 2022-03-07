use structopt::StructOpt;
use serde::{Deserialize,Serialize};

pub const UNIX_SOCKET_PATH: &str = "/tmp/fand.sock";
pub const TEMPERATRUE_FILENAME: &str = "/sys/class/thermal/thermal_zone0/temp";
pub const PIN_NUMBER: u8 = 22;

#[derive(Serialize,Deserialize,PartialEq,Eq,Debug)]
pub enum Command {
    SetHigh(u8),
    SetLow(u8),
    On,
    Off,
    Show,
}

#[derive(Debug, StructOpt)]
pub enum Action {
    /// Change high temperature.
    High {
        #[structopt()]
        temp: u8,
    },
    /// Change low temperature.
    Low {
        #[structopt()]
        temp: u8,
    },
    /// Monitor mode.
    Mon {
        #[structopt(default_value = "3")]
        duration: u8,
    },
    /// Server mode.
    Serv {
        #[structopt(default_value = "45")]
        low: u8,
        #[structopt(default_value = "65")]
        high: u8,
        #[structopt(default_value = "60")]
        duration: u8,
    },
    /// Turn fan on.
    On,
    /// Turn fan off.
    Off,
    /// Show current status
    Show,
}

#[derive(Debug, StructOpt)]
#[structopt(name = "fand", about = "A RPi fan control app.")]
pub struct CommandLineArgs {
    #[structopt(subcommand)]
    pub action: Action,
}
