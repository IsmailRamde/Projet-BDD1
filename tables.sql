drop table carte cascade ;
drop table forfait ;
drop table type_forfait;
drop table remontee cascade ;
drop table type_remontee cascade ;
drop table passage;

CREATE TABLE type_forfait
(
    id_type_forfait integer NOT NULL,
    libelle_type_forfait character varying(30) NOT NULL,
    prix numeric(3,0) NOT NULL,
    heure_debut time without time zone,
    heure_fin time without time zone,
    duree_forfait integer,
    condition character varying(30),
    CONSTRAINT pk PRIMARY KEY (id_type_forfait),
    CONSTRAINT checkprix CHECK (prix > 0::numeric AND NOT NULL),
    CONSTRAINT checkduree CHECK (duree_forfait IS NOT NULL)
);

CREATE TABLE public.carte
(
    id_carte integer NOT NULL,
    CONSTRAINT pkc PRIMARY KEY (id_carte)
);

CREATE TABLE public.forfait
(
    id_forfait integer NOT NULL,
    id_type_forfait integer,
    id_carte integer,
    date_debut date,
    CONSTRAINT pkf PRIMARY KEY (id_forfait),
    CONSTRAINT fk1 FOREIGN KEY (id_type_forfait) REFERENCES public.type_forfait (id_type_forfait),
    CONSTRAINT fk2 FOREIGN KEY (id_carte) REFERENCES public.carte (id_carte)
);

CREATE TABLE public.type_remontee
(
    id_type_remontee integer NOT NULL,
    libelle_type_remontee character varying(30) NOT NULL,
    CONSTRAINT pktr PRIMARY KEY (id_type_remontee)
);

CREATE TABLE public.remontee
(
    id_remontee integer NOT NULL,
    nom_remontee character varying(30) NOT NULL,
    duree_remontee interval,
    id_type_remontee integer,
    CONSTRAINT pkr PRIMARY KEY (id_remontee),
    CONSTRAINT fkr FOREIGN KEY (id_type_remontee) REFERENCES public.type_remontee (id_type_remontee),
    CONSTRAINT checknom_remontee CHECK (nom_remontee IS NOT NULL)
);

CREATE TABLE public.passage
(
    id_carte integer,
    id_remontee integer,
    heure_passage timestamp without time zone,
    CONSTRAINT fkp1 FOREIGN KEY (id_remontee) REFERENCES public.remontee (id_remontee),
    CONSTRAINT fkp2 FOREIGN KEY (id_carte) REFERENCES public.carte (id_carte)


);
