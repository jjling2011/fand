mod client;
mod configs;
mod server;

use configs::{Action, CommandLineArgs};
use structopt::StructOpt;

fn main() {
    let CommandLineArgs { action } = CommandLineArgs::from_args();
    match action {
        Action::On => client::on(),
        Action::Off => client::off(),
        Action::High { temp } => client::set_high(temp),
        Action::Low { temp } => client::set_low(temp),
        Action::Mon { duration } => client::mon(duration),
        Action::Show => client::show(),
        Action::Serv {
            low,
            high,
            duration,
        } => server::serv(low, high, duration),
    }
}
