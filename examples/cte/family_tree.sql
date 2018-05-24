--
-- PostgreSQL database dump
--

-- Dumped from database version 10.3
-- Dumped by pg_dump version 10.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: family_tree; Type: TABLE; Schema: public; Owner: luca
--

CREATE TABLE public.family_tree (
    pk integer NOT NULL,
    name text,
    parent_of integer,
    CONSTRAINT family_tree_check CHECK ((pk <> parent_of))
);


ALTER TABLE public.family_tree OWNER TO luca;

--
-- Name: family_tree_pk_seq; Type: SEQUENCE; Schema: public; Owner: luca
--

ALTER TABLE public.family_tree ALTER COLUMN pk ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.family_tree_pk_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Data for Name: family_tree; Type: TABLE DATA; Schema: public; Owner: luca
--

COPY public.family_tree (pk, name, parent_of) FROM stdin;
2	Diego	\N
1	Luca	2
3	Anselmo	1
5	Paolo	4
4	Emanuela	2
\.


--
-- Name: family_tree_pk_seq; Type: SEQUENCE SET; Schema: public; Owner: luca
--

SELECT pg_catalog.setval('public.family_tree_pk_seq', 5, true);


--
-- Name: family_tree family_tree_pkey; Type: CONSTRAINT; Schema: public; Owner: luca
--

ALTER TABLE ONLY public.family_tree
    ADD CONSTRAINT family_tree_pkey PRIMARY KEY (pk);


--
-- Name: family_tree family_tree_parent_of_fkey; Type: FK CONSTRAINT; Schema: public; Owner: luca
--

ALTER TABLE ONLY public.family_tree
    ADD CONSTRAINT family_tree_parent_of_fkey FOREIGN KEY (parent_of) REFERENCES public.family_tree(pk);


--
-- PostgreSQL database dump complete
--

