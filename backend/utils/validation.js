// Vérifications communes (inscription, connexion, profil).

// Email simple : quelque chose@quelque.chose, 150 caractères max
function emailValide(email) {
    return typeof email === "string"
        && email.length <= 150
        && /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email);
}

// Téléphone : on garde seulement les chiffres ("0661 23-45 67" → "0661234567").
// Renvoie null si vide. Le résultat peut être invalide : voir telephoneValide.
function normaliserTelephone(tel) {
    if (tel === undefined || tel === null) return null;
    const chiffres = String(tel).replace(/\D/g, "");
    return chiffres || null;
}

// 8 à 15 chiffres (numéros algériens : 10 chiffres)
function telephoneValide(chiffres) {
    return typeof chiffres === "string" && /^\d{8,15}$/.test(chiffres);
}

// Mot de passe : 8 caractères minimum, au moins une lettre et un chiffre.
// 72 caractères max (au-delà, bcrypt ignore la fin).
// Renvoie un message d'erreur, ou null si le mot de passe est correct.
function erreurMotDePasse(mdp) {
    if (typeof mdp !== "string" || mdp.length < 8) {
        return "Le mot de passe doit contenir au moins 8 caractères";
    }
    if (mdp.length > 72) return "Mot de passe trop long (72 caractères max)";
    if (!/[A-Za-zÀ-ÿ]/.test(mdp) || !/\d/.test(mdp)) {
        return "Le mot de passe doit contenir au moins une lettre et un chiffre";
    }
    return null;
}

// Date de naissance "AAAA-MM-JJ" : existe, après 1900, pas dans le futur
function dateNaissanceValide(v) {
    if (typeof v !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(v)) return false;
    const d = new Date(`${v}T00:00:00Z`);
    if (Number.isNaN(d.getTime()) || d.toISOString().slice(0, 10) !== v) return false;
    return v >= "1900-01-01" && d <= new Date();
}

module.exports = {
    emailValide,
    normaliserTelephone,
    telephoneValide,
    erreurMotDePasse,
    dateNaissanceValide
};
