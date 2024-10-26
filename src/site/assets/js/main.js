function add_card(cont, file, deletable) {
    // console.log(file)
    let card = document.createElement("button")
    card.className = "card";
    ur =
        card.innerHTML = `
        <img src="${file.file.type.substring(0, 5) === "image" ? URL.createObjectURL(file.file) : "assets/img/plik.svg"}" alt="${file.file.name}" style="width: 100%;">
        ${file.file.name}
    `
    if (deletable) { card.setAttribute("onclick", `usun(${file.id})`); }
    else { card.setAttribute("onclick", `zaznacz(${file.id})`); card.setAttribute("zaznacz", 0); }

    cont.appendChild(card);
}

function main() {
    _id = 0;
    files = []
    opfiles = []
    fs_menu = document.createElement("input")
    fs_menu.type = "file"
    fs_menu.multiple = true

    nr = -1
    sock = new WebSocket(`ws://${location.host}/ws`)

    sock.onopen = () => {
        sock.send("EVENT_give_id")
    }
    sock.onmessage = (msg) => {
        console.log(`ws mg: \n    ${msg.data}`)
        let json = ""
        try { json = JSON.parse(msg.data) } catch (err) { console.log(`{err}`); }
        if (json != "") {
            if (json.event == "give_id") {
                nr = json.id
            }
            if (json.event == "ask_me") {
                fetch("/loadfile",
                    {
                        method: 'POST',
                        body: `${nr}\\${json.id}`,
                        // responseType: 'text', // Explicitly set the responseType to 'text'
                        headers: {
                            'Content-Type': 'text/plain'
                        },
                    },
                );
            }
        }
    }

    me = document.querySelector("me files")
    you = document.querySelector("you files")

    // console.log(exports.add(1, 2));

    add_btn = document.querySelector("#add")
    add_btn.onclick = () => {
        fs_menu.click();
    }

    fs_menu.onchange = () => {
        i = 0;
        newFiles = Array.prototype.slice.call(fs_menu.files).map((e) => { return { id: -1, file: e }; })
        files = files.concat(newFiles)
        files = files.map((el) => { if (el.id == -1) { el.id = _id++; } return el; })

        for (file of newFiles) {
            add_card(me, file);
        }
        sendFiles(newFiles)
    }
}
