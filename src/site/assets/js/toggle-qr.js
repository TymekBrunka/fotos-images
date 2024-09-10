qr_btn = document.getElementById("qr-btn")
qr_code = document.getElementById("qr")

qr_btn.onclick = () => {
    if (qr_code.style.display != "none") {
        qr_code.style.display = "none"
    } else {
        qr_code.style.display = "inherit"
    }
}
