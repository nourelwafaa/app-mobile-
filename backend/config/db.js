const { Pool, types } = require("pg");

// Les dates (type DATE) restent telles quelles, ex : "2000-05-15"
// (sinon décalage de fuseau horaire → "2000-05-14T23:00:00.000Z")
types.setTypeParser(1082, (valeur) => valeur);

const db = new Pool({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME
});

module.exports = db;