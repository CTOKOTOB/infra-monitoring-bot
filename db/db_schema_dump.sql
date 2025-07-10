--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5 (Ubuntu 17.5-0ubuntu0.25.04.1)
-- Dumped by pg_dump version 17.5 (Ubuntu 17.5-0ubuntu0.25.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alerts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alerts (
    alert_id integer NOT NULL,
    server_id integer,
    metric_type character varying(20) NOT NULL,
    value double precision NOT NULL,
    threshold double precision NOT NULL,
    message text NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.alerts OWNER TO postgres;

--
-- Name: alerts_alert_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.alerts_alert_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.alerts_alert_id_seq OWNER TO postgres;

--
-- Name: alerts_alert_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.alerts_alert_id_seq OWNED BY public.alerts.alert_id;


--
-- Name: availability_checks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.availability_checks (
    check_id integer NOT NULL,
    server_id integer,
    is_available boolean NOT NULL,
    response_time double precision,
    error_message text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.availability_checks OWNER TO postgres;

--
-- Name: availability_checks_check_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.availability_checks_check_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.availability_checks_check_id_seq OWNER TO postgres;

--
-- Name: availability_checks_check_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.availability_checks_check_id_seq OWNED BY public.availability_checks.check_id;


--
-- Name: cpu_usage; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cpu_usage (
    usage_id integer NOT NULL,
    server_id integer,
    load_1m double precision NOT NULL,
    load_5m double precision NOT NULL,
    load_15m double precision NOT NULL,
    cpu_percent double precision NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.cpu_usage OWNER TO postgres;

--
-- Name: cpu_usage_usage_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cpu_usage_usage_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cpu_usage_usage_id_seq OWNER TO postgres;

--
-- Name: cpu_usage_usage_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cpu_usage_usage_id_seq OWNED BY public.cpu_usage.usage_id;


--
-- Name: disk_usage; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.disk_usage (
    usage_id integer NOT NULL,
    server_id integer,
    mount_point character varying(100) NOT NULL,
    total_gb double precision NOT NULL,
    used_gb double precision NOT NULL,
    used_percent double precision NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.disk_usage OWNER TO postgres;

--
-- Name: disk_usage_usage_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.disk_usage_usage_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.disk_usage_usage_id_seq OWNER TO postgres;

--
-- Name: disk_usage_usage_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.disk_usage_usage_id_seq OWNED BY public.disk_usage.usage_id;


--
-- Name: ram_usage; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ram_usage (
    usage_id integer NOT NULL,
    server_id integer,
    total_gb double precision NOT NULL,
    used_gb double precision NOT NULL,
    used_percent double precision NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.ram_usage OWNER TO postgres;

--
-- Name: ram_usage_usage_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ram_usage_usage_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ram_usage_usage_id_seq OWNER TO postgres;

--
-- Name: ram_usage_usage_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ram_usage_usage_id_seq OWNED BY public.ram_usage.usage_id;


--
-- Name: servers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.servers (
    server_id integer NOT NULL,
    name character varying(50) NOT NULL,
    ip_address character varying(15) NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    ssh_port integer DEFAULT 22
);


ALTER TABLE public.servers OWNER TO postgres;

--
-- Name: servers_server_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.servers_server_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.servers_server_id_seq OWNER TO postgres;

--
-- Name: servers_server_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.servers_server_id_seq OWNED BY public.servers.server_id;


--
-- Name: temperature_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.temperature_logs (
    log_id integer NOT NULL,
    temperature double precision NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.temperature_logs OWNER TO postgres;

--
-- Name: temperature_logs_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.temperature_logs_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.temperature_logs_log_id_seq OWNER TO postgres;

--
-- Name: temperature_logs_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.temperature_logs_log_id_seq OWNED BY public.temperature_logs.log_id;


--
-- Name: alerts alert_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts ALTER COLUMN alert_id SET DEFAULT nextval('public.alerts_alert_id_seq'::regclass);


--
-- Name: availability_checks check_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.availability_checks ALTER COLUMN check_id SET DEFAULT nextval('public.availability_checks_check_id_seq'::regclass);


--
-- Name: cpu_usage usage_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cpu_usage ALTER COLUMN usage_id SET DEFAULT nextval('public.cpu_usage_usage_id_seq'::regclass);


--
-- Name: disk_usage usage_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.disk_usage ALTER COLUMN usage_id SET DEFAULT nextval('public.disk_usage_usage_id_seq'::regclass);


--
-- Name: ram_usage usage_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ram_usage ALTER COLUMN usage_id SET DEFAULT nextval('public.ram_usage_usage_id_seq'::regclass);


--
-- Name: servers server_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.servers ALTER COLUMN server_id SET DEFAULT nextval('public.servers_server_id_seq'::regclass);


--
-- Name: temperature_logs log_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.temperature_logs ALTER COLUMN log_id SET DEFAULT nextval('public.temperature_logs_log_id_seq'::regclass);


--
-- Name: alerts alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (alert_id);


--
-- Name: availability_checks availability_checks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.availability_checks
    ADD CONSTRAINT availability_checks_pkey PRIMARY KEY (check_id);


--
-- Name: cpu_usage cpu_usage_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cpu_usage
    ADD CONSTRAINT cpu_usage_pkey PRIMARY KEY (usage_id);


--
-- Name: disk_usage disk_usage_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.disk_usage
    ADD CONSTRAINT disk_usage_pkey PRIMARY KEY (usage_id);


--
-- Name: ram_usage ram_usage_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ram_usage
    ADD CONSTRAINT ram_usage_pkey PRIMARY KEY (usage_id);


--
-- Name: servers servers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.servers
    ADD CONSTRAINT servers_pkey PRIMARY KEY (server_id);


--
-- Name: temperature_logs temperature_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.temperature_logs
    ADD CONSTRAINT temperature_logs_pkey PRIMARY KEY (log_id);


--
-- Name: alerts alerts_server_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_server_id_fkey FOREIGN KEY (server_id) REFERENCES public.servers(server_id);


--
-- Name: availability_checks availability_checks_server_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.availability_checks
    ADD CONSTRAINT availability_checks_server_id_fkey FOREIGN KEY (server_id) REFERENCES public.servers(server_id);


--
-- Name: cpu_usage cpu_usage_server_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cpu_usage
    ADD CONSTRAINT cpu_usage_server_id_fkey FOREIGN KEY (server_id) REFERENCES public.servers(server_id);


--
-- Name: disk_usage disk_usage_server_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.disk_usage
    ADD CONSTRAINT disk_usage_server_id_fkey FOREIGN KEY (server_id) REFERENCES public.servers(server_id);


--
-- Name: ram_usage ram_usage_server_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ram_usage
    ADD CONSTRAINT ram_usage_server_id_fkey FOREIGN KEY (server_id) REFERENCES public.servers(server_id);


--
-- Name: TABLE alerts; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.alerts TO monuser;


--
-- Name: SEQUENCE alerts_alert_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.alerts_alert_id_seq TO monuser;


--
-- Name: TABLE availability_checks; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.availability_checks TO monuser;


--
-- Name: SEQUENCE availability_checks_check_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.availability_checks_check_id_seq TO monuser;


--
-- Name: TABLE cpu_usage; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.cpu_usage TO monuser;


--
-- Name: SEQUENCE cpu_usage_usage_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.cpu_usage_usage_id_seq TO monuser;


--
-- Name: TABLE disk_usage; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.disk_usage TO monuser;


--
-- Name: SEQUENCE disk_usage_usage_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.disk_usage_usage_id_seq TO monuser;


--
-- Name: TABLE ram_usage; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.ram_usage TO monuser;


--
-- Name: SEQUENCE ram_usage_usage_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.ram_usage_usage_id_seq TO monuser;


--
-- Name: TABLE servers; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.servers TO monuser;


--
-- Name: SEQUENCE servers_server_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.servers_server_id_seq TO monuser;


--
-- Name: TABLE temperature_logs; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.temperature_logs TO monuser;


--
-- Name: SEQUENCE temperature_logs_log_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.temperature_logs_log_id_seq TO monuser;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO monuser;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO monuser;


--
-- PostgreSQL database dump complete
--


ALTER TABLE servers
ADD COLUMN connect_user VARCHAR(50),
ADD COLUMN connect_password VARCHAR(100);

ALTER TABLE servers
RENAME COLUMN connect_password TO connect_password_enc;

CREATE TABLE user_settings (
    user_id BIGINT PRIMARY KEY,
    hours_depth INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE allowed_users (
    user_id BIGINT PRIMARY KEY,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
