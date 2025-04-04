#![no_std]
#![no_main]

use core::panic::PanicInfo;
use embedded_hal::digital::v2::OutputPin;
use esp32_hal::{
    clock::ClockControl,
    entry,
    gpio::*,
    i2c::I2C,
    peripherals::Peripherals,
    prelude::*,
    Delay,
    IO,
};

#[entry]
fn main() -> ! {
    let peripherals = Peripherals::take();
    let system = peripherals.SYSTEM.split();
    let clocks = ClockControl::boot_defaults(system.clock_control).freeze();

    let io = IO::new(peripherals.GPIO, peripherals.IO_MUX);
    let mut delay = Delay::new(&clocks);

    let mut led = io.pins.gpio10.into_push_pull_output();

    let sda = io.pins.gpio21;
    let scl = io.pins.gpio22;
    let mut i2c = I2C::new(peripherals.I2C0, scl, sda, 400u32.kHz(), &clocks);

    let mut buffer = [0u8];
    let addr = 0x68u8;
    let reg = 0x75u8;

    match i2c.write_read(addr, &[reg], &mut buffer) {
        Ok(_) => {
            blink(&mut delay, &mut led, buffer[0]);
        }
        Err(_) => {
            blink(&mut delay, &mut led, 5);
        }
    }
}

fn blink(delay: &mut Delay, led: &mut impl OutputPin, count: u8) -> ! {
    loop {
        for _ in 0..count {
            led.set_high().ok();
            delay.delay_ms(150u32);
            led.set_low().ok();
            delay.delay_ms(150u32);
        }
        delay.delay_ms(1000u32);
    }
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}
