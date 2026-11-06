-- =========================================
-- Creative Lupus+ : Partie 5 — LupIA, conseils, notifications, mot de passe oublié
-- =========================================

-- 1. Historique des conversations avec LupIA
CREATE TABLE lupia_messages (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    emetteur VARCHAR(10) NOT NULL
        CHECK (emetteur IN ('user', 'lupia')),
    contenu TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Conseils et astuces (nutrition, activité physique, bien-être)
CREATE TABLE conseils (
    id SERIAL PRIMARY KEY,
    categorie VARCHAR(20) NOT NULL
        CHECK (categorie IN ('nutrition', 'activite_physique', 'bien_etre')),
    titre VARCHAR(150) NOT NULL,
    contenu TEXT NOT NULL,
    image_url VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Notifications (rappels médicaments, RDV, analyses, messages, alertes)
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL
        CHECK (type IN ('medicament', 'rendez_vous', 'analyse', 'message', 'alerte', 'autre')),
    titre VARCHAR(150) NOT NULL,
    message TEXT,
    lue BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Mot de passe oublié (code de réinitialisation temporaire)
CREATE TABLE reset_mot_de_passe (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code VARCHAR(255) NOT NULL,
    expire_le TIMESTAMP NOT NULL,
    utilise BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);