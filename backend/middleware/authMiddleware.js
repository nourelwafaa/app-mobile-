const jwt = require("jsonwebtoken");

// Vérifie que la requête contient un token valide
exports.verifierToken = (req, res, next) => {
    const header = req.headers.authorization;

    if (!header || !header.startsWith("Bearer ")) {
        return res.status(401).json({ message: "Vous devez être connecté" });
    }

    try {
        const token = header.split(" ")[1];
        req.user = jwt.verify(token, process.env.JWT_SECRET); // { id, role }
        next();
    } catch (error) {
        return res.status(401).json({ message: "Session expirée, reconnectez-vous" });
    }
};

// Autorise seulement certains rôles (ex : "patient", "medecin")
exports.autoriserRoles = (...roles) => (req, res, next) => {
    if (!roles.includes(req.user.role)) {
        return res.status(403).json({ message: "Accès refusé" });
    }
    next();
};