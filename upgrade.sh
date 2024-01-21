sudo git fetch

git checkout polkadot-v1.6.0

rustup component add rust-src

sudo apt install rustup component add rust-src -y

rustup target add wasm32-unknown-unknown

rustup install nightly-2023-05-22

rustup target add wasm32-unknown-unknown --toolchain nightly-2023-05-22

sudo apt-get install -y git clang curl make libssl-dev llvm libudev-dev protobuf-compiler

rustup update

cargo build --release

