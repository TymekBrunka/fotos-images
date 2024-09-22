var memory = new WebAssembly.Memory({
    // See build.zig for reasoning
    initial: 2 /* pages */,
    maximum: 2 /* pages */,
});

//from https://github.com/daneelsan/zig-wasm-logger/blob/master/script.js
const text_decoder = new TextDecoder();
let console_log_buffer = "";

let wasm = {
    instance: undefined,

    init: function(obj) {
        this.instance = obj.instance;
    },
    getString: function(ptr, len) {
        const memory = this.instance.exports.memory;
        return text_decoder.decode(new Uint8Array(memory.buffer, ptr, len));
    },
};
//^

var importObject = {
    env: {
        //from https://github.com/daneelsan/zig-wasm-logger/blob/master/script.js
        jsConsoleLogWrite: function(ptr, len) {
            console_log_buffer += wasm.getString(ptr, len);
        },
        jsConsoleLogFlush: function() {
            console.log(console_log_buffer);
            console_log_buffer = "";
        },
        //^
        memory: memory,
    },
};

//from https://github.com/daneelsan/zig-wasm-logger/blob/master/script.js
async function bootstrap() {
    wasm.init(await WebAssembly.instantiateStreaming(fetch("assets/wasm/site.wasm"), importObject));
    exports = wasm.instance.exports;
    main();
}

bootstrap()
