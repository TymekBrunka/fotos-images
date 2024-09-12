var memory = new WebAssembly.Memory({
    // See build.zig for reasoning
    initial: 1 /* pages */,
    maximum: 1 /* pages */,
});

var importObject = {
    env: {
        consoleLog: (arg) => console.log(arg), // Useful for debugging on zig's side
        memory: memory,
    },
};

WebAssembly.instantiateStreaming(fetch("assets/wasm/site.wasm"), importObject).then((result) => {
    res = result;
    // console.log(add(1, 2));
});
