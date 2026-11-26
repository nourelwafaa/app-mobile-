-- =========================================
-- Creative Lupus+ : Partie 8 — Sécurité des comptes
-- =========================================
-- À exécuter une fois dans pgAdmin (base creative_lupus), après les fichiers 01 à 07.
-- Le script peut être relancé sans erreur.

-- Les téléphones sont maintenant enregistrés avec seulement les chiffres
-- ("0661 23 45 67" → "0661234567"), à l'inscription comme à la connexion.
-- On nettoie ceux qui existent déjà (sinon la connexion par téléphone échouerait).
UPDATE users
SET telephone = NULLIF(regexp_replace(telephone, '\D', '', 'g'), '')
WHERE telephone IS NOT NULL
  AND telephone ~ '\D';
