

-- Créations des triggers 


create or replace function carte_utilisee() returns trigger as $carte_util$
declare

nb_forfaits integer ;
new_date_debut date;
new_duree_forfait integer ;

begin

-- on teste la date de debut du nouveau forfait
-- s'il est null alors on met la date du jour dans new_date_debut
if (new.date_debut is null) then
	new_date_debut = (select current_date);
else
	new_date_debut = new.date_debut;
end if;

-- on recupere la duree du forfait
new_duree_forfait = (select duree_forfait from type_forfait where id_type_forfait=new.id_type_forfait) ;
-- requete qui compte le nombre de forfait valide utilisant la carte
nb_forfaits = (select count (f.id_forfait) from forfait f,type_forfait t where (f.date_debut,f.date_debut+t.duree_forfait) overlaps (new_date_debut,new_date_debut+new_duree_forfait) and f.id_type_forfait=t.id_type_forfait and f.id_carte = new.id_carte);

---

if (nb_forfaits > 0) then 
	raise exception 'la carte % n''est pas disponible!!!',new.id_carte;
end if ;
new.date_debut = new_date_debut;
return new ;
end

$carte_util$ language plpgsql;

create trigger carte_utilisee before insert
	on forfait for each row 
	execute procedure carte_utilisee();
	
--- Creation d'un trigger verifiant la contrainte 3

create or replace function forfait_invalide() returns trigger as $forfait_inv$
declare

new_heure_debut time without time zone;
new_heure_fin time without time zone;
new_libelle_type_forfait character varying(30);
new_duree_forfait integer;
new_date_debut date;
new_id_forfait integer;
nb_carte integer;

begin

-- on recupere libelle_type_forfait
new_libelle_type_forfait = (select t.libelle_type_forfait from type_forfait t,forfait f where new.id_carte=f.id_carte and f.id_type_forfait=t.id_type_forfait);

-- on recupere la duree du forfait
new_duree_forfait = (select t.duree_forfait from type_forfait t,forfait f where new.id_carte=f.id_carte and f.id_type_forfait=t.id_type_forfait);
new_date_debut = (select f.date_debut from forfait f where f.id_carte=new.id_carte);

-- On recupere l'ID du nouvel forfait
new_id_forfait = (select f.id_forfait from forfait f where f.id_carte = new.id_carte);

-- requete qui compte le nombre de carte utilisant le meme forfait
nb_carte = (select count(p.id_carte) from passage p,forfait f where (new.heure_passage,new.heure_passage) 
overlaps(p.heure_passage,p.heure_passage) and p.id_carte=new.id_carte and f.id_forfait = new_id_forfait);

if(new_libelle_type_forfait='matinée') then

	if(select(new_date_debut + interval '09:00:00',new_date_debut + interval '14:00:00' + interval '1 day') overlaps (new.heure_passage,new.heure_passage + interval '14:00:00') = false or
	 new_duree_forfait > 1 or nb_carte > 0) then
			raise exception 'le forfait % de la carte % n''est pas valide!!!',new_id_forfait,new.id_carte;
	end if;
end if;
if(new_libelle_type_forfait='semaine') then

	if(select(new_date_debut + interval '09:00:00',new_date_debut + interval '17:00:00' + interval '7 day') overlaps (new.heure_passage,new.heure_passage + interval '14:00:00') = false or
	 new_duree_forfait > 7 or nb_carte > 0) then
			raise exception 'le forfait % de la carte % n''est pas valide!!!',new_id_forfait,new.id_carte;
	end if;
end if;
if(new_libelle_type_forfait='journée') then

	if(select(new_date_debut + interval '09:00:00',new_date_debut + interval '17:00:00' + interval '1 day') overlaps (new.heure_passage,new.heure_passage + interval '14:00:00') = false or
	 new_duree_forfait > 1 or nb_carte > 0) then
			raise exception 'le forfait % de la carte % n''est pas valide!!!',new_id_forfait,new.id_carte;
	end if;
end if;
return new;
end

$forfait_inv$ language plpgsql;

create trigger forfait_invalide before insert
	on passage for each row 
	execute procedure forfait_invalide();
	



--FIN