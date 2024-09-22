async function stringiFile(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();

        reader.onload = (event) => {
            const fileData = event.target.result;
            resolve(fileData);
        };

        reader.onerror = (error) => {
            reject(error);
        };

        reader.readAsDataURL(file);
    });
}

async function sendFiles(files) {
    const newFiles = files.map(async (e) => {
        const fileData = await stringiFile(e.file);
        return [
            e.id, //id
            e.file.type, //ft
            // e.file.size, //size
            e.file.name, //name
            fileData //data
        ].join("\\");
    });

    const resolvedFiles = await Promise.all(newFiles);

    for (fil of resolvedFiles) {
        fetch("/sendfiles",

            {
                method: 'POST',
                body: `${nr}\\${fil}`,
                // responseType: 'text', // Explicitly set the responseType to 'text'
                headers: {
                    'Content-Type': 'text/plain'
                },
            },
        );
    }

    console.log("sending: ")
    console.log(`${nr};${resolvedFiles.join("\\")}`)
}
