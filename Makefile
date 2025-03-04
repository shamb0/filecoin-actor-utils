build: install-toolchain
	cargo build --workspace

check: install-toolchain
	cargo fmt --check
	cargo clippy --workspace -- -D warnings

check-build: check
	cargo build --workspace

# run all tests, this will not work if using RUSTFLAGS="-Zprofile" to generate profile info or coverage reports
# as any WASM targets will fail to build
test: install-toolchain
	cargo test

# tests excluding actors so we can generate coverage reports during CI build
# WASM targets such as actors do not support this so are excluded
test-coverage: install-toolchain
	cargo test --workspace \
		--exclude greeter \
		--exclude fil_token_integration_tests \
		--exclude basic_token_actor \
		--exclude basic_receiving_actor \
		--exclude basic_nft_actor \
		--exclude basic_transfer_actor \
		--exclude frc46_test_actor \
		--exclude frc46_factory_token \
		--exclude frc53_test_actor

# separate actor testing stage to run from CI without coverage support
test-actors: install-toolchain
	cargo test --package greeter --package fil_token_integration_tests

install-toolchain:
	rustup update
	rustup component add rustfmt
	rustup component add clippy
	rustup target add wasm32-unknown-unknown

clean:
	cargo clean
	find . -name '*.profraw' -delete
	rm Cargo.lock

# generate local coverage report in html format using grcov
# install it with `cargo install grcov`
# TODO: fix the output path for LLVM_PROFILE_FILE 
local-coverage:
	CARGO_INCREMENTAL=0 RUSTFLAGS='-Cinstrument-coverage' LLVM_PROFILE_FILE='target/coverage/raw/cargo-test-%p-%m.profraw' cargo test --workspace \
		--exclude greeter \
		--exclude fil_token_integration_tests \
		--exclude basic_token_actor \
		--exclude basic_receiving_actor \
		--exclude basic_nft_actor \
		--exclude basic_transfer_actor \
		--exclude frc46_test_actor \
		--exclude frc46_factory_token \
		--exclude frc53_test_actor
	grcov . --binary-path ./target/debug/deps/ -s . -t html --branch --ignore-not-existing --ignore '../*' --ignore "/*" -o target/coverage/html
