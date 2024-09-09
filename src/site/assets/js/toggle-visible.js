const holder = document.querySelector("holder")

const me_btn = document.querySelector("me > .barr")
me_btn.onclick = () => {
    if (holder.classList.toggle("hid-me")) {
        holder.classList.remove("hid-you")
    } else {
        holder.classList.add("hid-you")
    }
}

const you_btn = document.querySelector("you > .barr")
you_btn.onclick = () => {
    if (holder.classList.toggle("hid-you")) {
        holder.classList.remove("hid-me")
    } else {
        holder.classList.add("hid-me")
    }
}
