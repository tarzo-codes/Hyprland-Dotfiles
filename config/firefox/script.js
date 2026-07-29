function getUsername() {
    // Option A — Check if username is passed in URL (file:///path/index.html?user=bob)
    const params = new URLSearchParams(window.location.search);
    if (params.has("user")) {
        const name = params.get("user");
        localStorage.setItem("savedUsername", name);
        return name;
    }

    // Option B — Check localStorage
    const saved = localStorage.getItem("savedUsername");
    if (saved) return saved;

    // Ask user once and save it
    const entered = prompt("Enter Linux username:");
    if (entered) {
        localStorage.setItem("savedUsername", entered);
        return entered;
    }

    return "User"; // fallback
}

document.getElementById("welcome").textContent = `Welcome, ${getUsername()}!`;

