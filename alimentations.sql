insert into type_forfait (select distinct id_type_forfait,libelle_type_forfait,prix,heure_debut,heure_fin,duree_forfait,
	condition from bd_station);

insert into carte (select distinct id_carte from bd_station);

insert into forfait (select distinct id_forfait ,id_type_forfait,id_carte,date_debut from bd_station );

insert into type_remontee (select distinct id_type_remontee,libelle_type_remontee from bd_station);

insert into remontee (select distinct id_remontee,nom_remontee,duree_remontee,id_type_remontee from bd_station);

insert into passage (select distinct id_carte,id_remontee,heure_passage from bd_station);