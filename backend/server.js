const express = require("express");
const cors = require("cors");
require("dotenv").config();

const db = require("./config/db");
const authRoutes = require("./routes/authRoutes");

const app = express();

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
    res.json({
        message: "Bienvenue dans Creative Lupus+ Backend"
    });
});

app.get("/api/test-db", async (req, res) => {
    try {
        const result = await db.query("SELECT 1 AS connected");

        res.json({
            message: "PostgreSQL connecté !",
            connected: result.rows[0].connected
        });
    } catch (error) {
        console.error("Erreur PostgreSQL :", error.message);
        res.status(500).json({
            message: "Erreur de connexion à PostgreSQL"
        });
    }
});

// Routes d'authentification
app.use("/api/auth", authRoutes);

const PORT = process.env.PORT || 3001;

app.listen(PORT, () => {
    console.log(`Serveur démarré sur le port ${PORT}`);
});