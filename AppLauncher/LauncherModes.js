.pragma library

function detectPrefixMode(query) {
    const t = (query || "").replace(/^\s+/, "");
    if (t.startsWith("=")) return "calc";
    if (t.startsWith("@")) return "window";
    return "apps";
}

function stripPrefix(query) {
    const t = (query || "").replace(/^\s+/, "");
    if (t.startsWith("=") || t.startsWith("@")) {
        return t.slice(1).trim();
    }
    return t.trim();
}

function evalMath(rawExpr) {
    const expr = (rawExpr || "").trim();
    if (expr === "") return { ok: false, result: "", hint: "Type a math expression (e.g. 25 * 48, sqrt(144), 2^10)" };

    // Replace friendly math syntax with JS Math equivalents
    let normalized = expr
        .replace(/\^/g, "**")
        .replace(/\bpi\b/gi, "Math.PI")
        .replace(/\be\b/g, "Math.E")
        .replace(/\b(sqrt|abs|round|floor|ceil|sin|cos|tan|log|min|max|pow)\b/gi, function(m) {
            return "Math." + m.toLowerCase();
        });

    // Strict character whitelist before evaluation
    const stripped = normalized.replace(/Math\.(PI|E|sqrt|abs|round|floor|ceil|sin|cos|tan|log|min|max|pow)/g, "");
    if (!/^[0-9+\-*/%().,\s*]*$/.test(stripped)) {
        return { ok: false, result: "", hint: "Unsupported characters in expression" };
    }

    try {
        const fn = new Function("return (" + normalized + ");");
        const val = fn();
        if (typeof val !== "number" || !isFinite(val)) {
            return { ok: false, result: "", hint: "Invalid or undefined result" };
        }
        const rounded = Math.abs(val - Math.round(val)) < 1e-10 ? Math.round(val) : Number(val.toPrecision(12));
        return { ok: true, result: String(rounded), hint: "Press Enter or click to copy to clipboard" };
    } catch (e) {
        return { ok: false, result: "", hint: "Keep typing..." };
    }
}
