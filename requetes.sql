-- LES REQUETES SQL

-- 1. Le dernier forfait valide correspondant à un identifiant de carte donné (exemple : carte n°1)

SELECT id_forfait 
FROM forfait 
WHERE id_carte = 1 
	AND DATE_DEBUT = (SELECT MAX(date_debut) 
					  FROM forfait 
					  WHERE id_carte = 1);



-- 2. Les noms des remontées de type ’télésiège’

SELECT r.nom_remontee 
FROM remontee r, type_remontee tr 
WHERE tr.id_type_remontee = r.id_type_remontee 
	AND tr.libelle_type_remontee = 'télésiège';



-- 3.Les remontées de type ’télésiège’ empruntées avec le forfait n°1

SELECT DISTINCT r.id_remontee, r.nom_remontee, t.libelle_type_remontee 
FROM remontee r, type_remontee t, passage p, forfait f,type_forfait tf
WHERE r.id_type_remontee = t.id_type_remontee 
	AND p.id_carte = f.id_carte 
	AND r.id_remontee = p.id_remontee 
	AND p.heure_passage BETWEEN f.date_debut + tf.heure_debut 
	AND f.date_debut + (tf.duree_forfait-1) * interval '1 day' + tf.heure_fin
	AND t.libelle_type_remontee = 'télésiège' 
	AND f.id_forfait = 1;




-- 4. Les noms des remontées non empruntées avec le forfait n°2

SELECT nom_remontee 
FROM remontee
EXCEPT
    SELECT DISTINCT r.nom_remontee 
    FROM remontee r, passage p, forfait f,type_forfait tf
    WHERE p.id_remontee = r.id_remontee 
        AND p.id_carte = f.id_carte 
        AND p.heure_passage BETWEEN f.date_debut + tf.heure_debut 
		AND f.date_debut + (tf.duree_forfait-1) * interval '1 day' + tf.heure_fin
        AND f.id_forfait = 2;




-- 5. Pour chaque type de forfait, le nombre de forfaits vendus

SELECT tf.libelle_type_forfait, COUNT(f.id_forfait) AS Nb_forfait_vendus
FROM type_forfait tf, forfait f 
WHERE tf.id_type_forfait = f.id_type_forfait
GROUP BY tf.libelle_type_forfait;



-- 6 Le nombre de forfaits qui ont été utilisés sur toutes les remontées de la station

SELECT COUNT(*) 
FROM (SELECT DISTINCT(id_forfait) FROM forfait f, passage p, type_forfait tf
    	WHERE f.id_carte = p.id_carte
     		AND f.id_type_forfait = tf.id_type_forfait 
	 		AND p.heure_passage BETWEEN f.date_debut + tf.heure_debut 
	 		AND f.date_debut + (tf.duree_forfait-1) * interval '1 day' + tf.heure_fin
    	GROUP BY id_forfait
   	    HAVING COUNT(DISTINCT(id_remontee)) =(SELECT COUNT(id_remontee) 
											   FROM remontee)) 
			   AS Nb_forfaits_utilises;


-- 7. Les cartes qui ont été les plus ré-utilisées (c’est à dire associées au plus grand nombre de forfaits)  

SELECT id_carte, COUNT(*) AS Nb_forfait 
FROM forfait 
GROUP BY id_carte 
HAVING COUNT(*) >= ALL(SELECT COUNT(*) AS Nb_forfait 
					   FROM forfait
					   GROUP BY id_carte);



-- 8. Le nombre de passages enregistrés pour chaque remontée 

SELECT p.id_remontee, r.nom_remontee, COUNT(*) AS Nb_Passages 
FROM passage p, remontee r 
WHERE p.id_remontee = r.id_remontee 
GROUP BY p.id_remontee, r.nom_remontee 
ORDER BY p.id_remontee ASC;



--9. Pour, chaque jour, le nombre de passages enregistrés pour chaque remontée

SELECT DISTINCT r.id_remontee, r.nom_remontee, DATE_TRUNC('day', p.heure_passage) AS Jour, COUNT(*) AS Nb_passages 
FROM passage p, forfait f, remontee r, type_forfait tf
WHERE p.id_carte = f.id_carte 
	AND p.id_remontee = r.id_remontee
	AND tf.id_type_forfait = f.id_type_forfait
	AND p.heure_passage BETWEEN f.date_debut + tf.heure_debut 
	AND f.date_debut + (tf.duree_forfait-1) * interval '1 day' + tf.heure_fin
GROUP BY DATE_TRUNC('day', p.heure_passage), r.id_remontee, r.nom_remontee 
ORDER BY DATE_TRUNC('day', p.heure_passage) ASC;



-- 10. La remontée la plus fréquentée (où il y a eu le plus de passages) 

SELECT p.id_remontee,r.nom_remontee, COUNT(*) AS Nb_remontee 
FROM passage p, remontee r 
WHERE p.id_remontee = r.id_remontee 
GROUP BY p.id_remontee, r.nom_remontee 
HAVING COUNT(*) >= ALL(SELECT COUNT(*) AS Nb_remontee 
					  FROM passage p, remontee r 
					  WHERE p.id_remontee = r.id_remontee 
					  GROUP BY p.id_remontee, r.nom_remontee);



-- 11. Le télésiège le moins fréquenté

SELECT p.id_remontee, r.nom_remontee, t.libelle_type_remontee, COUNT(*) AS Nb_remontee 
FROM passage p, remontee r, type_remontee t 
WHERE p.id_remontee = r.id_remontee 
	AND r.id_type_remontee = t.id_type_remontee 
	AND t.libelle_type_remontee = 'télésiège'
GROUP BY p.id_remontee, r.nom_remontee, t.libelle_type_remontee 
HAVING COUNT(*) <= ALL(SELECT COUNT(*) AS Nb_remontee 
					   FROM passage p, remontee r, type_remontee t 
					   WHERE p.id_remontee = r.id_remontee 
					 	  AND r.id_type_remontee = t.id_type_remontee 
					 	  AND t.libelle_type_remontee = 'télésiège'
						GROUP BY p.id_remontee, r.nom_remontee, t.libelle_type_remontee);



-- 12. Le(s) forfait(s) ayant servi le plus de fois sur une journée

SELECT f.id_forfait, t.libelle_type_forfait, COUNT(*) as Nb_fois_utlilse
FROM passage p, forfait f, type_forfait t
WHERE p.id_carte = f.id_carte
	AND f.id_type_forfait = t.id_type_forfait
GROUP BY DATE_TRUNC('year', p.heure_passage),
        DATE_TRUNC('month', p.heure_passage),
        DATE_TRUNC('day', p.heure_passage),
		f.id_forfait, t.libelle_type_forfait
HAVING COUNT(*) = (SELECT MAX(Maxi) 
            	   FROM (SELECT f.id_forfait, t.libelle_type_forfait, COUNT(*) as Maxi 
                   FROM passage p, forfait f, type_forfait t
                   WHERE p.id_carte = f.id_carte
					   AND f.id_type_forfait = t.id_type_forfait
                   GROUP BY DATE_TRUNC('year', p.heure_passage),
                            DATE_TRUNC('month', p.heure_passage),
                            DATE_TRUNC('day', p.heure_passage),
                            f.id_forfait, t.libelle_type_forfait) skiier);



-- 13. le chiffre d’affaire de la station (somme des prix des forfaits vendus) 

SELECT SUM(t.prix) AS Chiffre_affaire 
FROM type_forfait t, forfait f 
WHERE t.id_type_forfait = f.id_type_forfait;



-- 14 le chiffre d’affaire de la station ventilé par mois (pour les forfaits à cheval sur 2 mois, 
-- on les compte par rapport à leur date de début de validité)

SELECT date_trunc('month', f.date_debut) AS Mois, SUM(t.prix) AS Chiffre_affaire 
FROM type_forfait t, forfait f 
WHERE t.id_type_forfait = f.id_type_forfait
GROUP BY DATE_TRUNC('month', f.date_debut) 
ORDER BY DATE_TRUNC('month', f.date_debut) ASC;

