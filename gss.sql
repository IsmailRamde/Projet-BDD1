
drop table carte ;
drop table forfait ;
drop table type_forfait;
drop table remontee cascade ;
drop table type_remontee cascade ;
drop table passage ;

-- Creation de la table type_forfait

select distinct id_type_forfait,libelle_type_forfait,prix,heure_debut,heure_fin,duree_forfait,condition into type_forfait from bd_station;
alter table type_forfait add constraint pk primary key (id_type_forfait);
alter table type_forfait add constraint checkprix check(prix>0 and not null);
alter table type_forfait add constraint checkduree check(duree_forfait is not null);

-- Creation de la table carte

select distinct id_carte into carte from bd_station ;
alter table carte add constraint pkc primary key (id_carte);

-- Creation de la table forfait

select distinct id_forfait ,id_type_forfait,id_carte,date_debut into forfait from bd_station ;
alter table forfait add constraint pkf primary key (id_forfait);
alter table forfait add constraint fk1 foreign key (id_type_forfait) references type_forfait(id_type_forfait);

-- Creation de la table type_remontée

select distinct id_type_remontee,libelle_type_remontee into type_remontee from bd_station ;
alter table type_remontee add constraint pktr primary key (id_type_remontee) ;
 
-- Creation de la table remontee

select distinct id_remontee,nom_remontee,duree_remontee,id_type_remontee into remontee from bd_station ;
alter table remontee add constraint pkr primary key (id_remontee) ;
alter table remontee add constraint fkr foreign key (id_type_remontee) references type_remontee(id_type_remontee);

-- Creation de la table passage

select distinct id_carte, id_remontee, heure_passage into passage from bd_station ;
alter table passage add constraint fkp foreign key (id_remontee) references remontee(id_remontee) ;


--- Creation d'un trigger verifiant la contrainte 1 et 2

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

begin
-- on recupere heure_debut
new_heure_debut = (select t.heure_debut from type_forfait t,forfait f where new.id_carte=f.id_carte and f.id_type_forfait=t.id_type_forfait);

-- on recupere heure_fin
new_heure_fin = (select t.heure_fin from type_forfait t,forfait f where new.id_carte=f.id_carte and f.id_type_forfait=t.id_type_forfait);

-- on recupere libelle_type_forfait
new_libelle_type_forfait = (select t.libelle_type_forfait from type_forfait t,forfait f where new.id_carte=f.id_carte and f.id_type_forfait=t.id_type_forfait);

-- on recupere la duree du forfait
new_duree_forfait = (select t.duree_forfait from type_forfait t,forfait f where new.id_carte=f.id_carte and f.id_type_forfait=t.id_type_forfait);

if(new_libelle_type_forfait='matinée') then

	if(select(time without time zone '09:00:00',time without time zone '14:00:00') overlaps (new_heure_debut,new_heure_fin) = false or
	 new_duree_forfait > 1) then
			raise exception 'le forfait de la carte % n''est pas valide!!!',new.id_carte;
	end if;
end if;
if(new_libelle_type_forfait='semaine') then

	if(select(time without time zone '09:00:00',time without time zone '17:00:00') overlaps (new_heure_debut,new_heure_fin) = false or 
		new_duree_forfait > 7) then
			raise exception 'le forfait de la carte % n''est pas valide!!!',new.id_carte;
	end if;
end if;
if(new_libelle_type_forfait='journée') then

	if(select(time without time zone '09:00:00',time without time zone '17:00:00') overlaps (new_heure_debut,new_heure_fin) = false or 
		new_duree_forfait > 1) then
			raise exception 'le forfait de la carte % n''est pas valide!!!',new.id_carte;
	end if;
end if;

return new;					
end

$forfait_inv$ language plpgsql;

create trigger forfait_invalide before insert
	on passage for each row 
	execute procedure forfait_invalide();
	
-- Requetes pour tester les trigger

insert into forfait values(25001,2,5934); -- insertion d'un nouveau forfait dont la date debut est null
insert into forfait values(25002,2,5934) ;

insert into type_forfait values(25,'semaine',20,'9:00:00','17:00:00',8);
insert into forfait values(25003,25,7001,'20-12-2020');
insert into passage values(7001,2,'2008-12-27 11:21:43.28');


-- Les requetes SQL

--Quel est le dernier forfait valide correspondant à un identifiant de carte donné (exemple : carte n°1)

select max(id_forfait) from forfait where id_carte=1 ;

-- 2.Quels sont les noms des remontées de type ’télésiège’
select r.nom_remontee from remontee r,type_remontee tr where tr.id_type_remontee=r.id_type_remontee and tr.libelle_type_remontee='télésiège';

--3.Quels sont les remontées de type ’télésiège’ empruntées avec le forfait n°1
select distinct r.id_remontee,r.nom_remontee from remontee r,type_remontee tr,passage p,forfait f where 
tr.id_type_remontee=r.id_type_remontee and p.id_remontee=r.id_remontee and p.id_carte=f.id_carte and tr.libelle_type_remontee='télésiège' 
and f.id_forfait=1;

--4. Quelles sont les noms des remontées non empruntées avec le forfait n°2
select nom_remontee from remontee
except
select distinct r.nom_remontee from remontee r,passage p,forfait f where p.id_remontee=r.id_remontee and p.id_carte=f.id_carte and 
f.id_forfait=2;

--5. 

select libelle_type_forfait,count(libelle_type_forfait) from type_forfait
group by libelle_type_forfait;

--6 Combien de forfaits ont été utilisés sur toutes les remontées de la station

select count(f.id_forfait) 
from forfait f,passage p where p.id_carte=f.id_carte;



