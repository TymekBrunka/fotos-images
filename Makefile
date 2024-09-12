all:
	zig build
	cp zig-out/bin/site.wasm src/site/assets/wasm/site.wasm
	zig build run
