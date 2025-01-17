-- Run this file to initialize the database, schema, and tables for PurpleAir Monitor Readings in Minneapolis
-- You can run this by using a psql command like:
-- psql "host=postgres.cla.umn.edu user=<your_username> password=<your_password> " -f initializedb.sql

-- To Do beforehand

-- CREATE DATABASE "spike_alerts"; -- Create the database

--\c "SpikeAlerts"; -- Connect to database This needs a password!
DROP SCHEMA IF EXISTS staging CASCADE;
DROP EXTENSION IF EXISTS postgis CASCADE;
DROP EXTENSION IF EXISTS postgis_topology CASCADE;

CREATE SCHEMA staging;
CREATE EXTENSION postgis; -- Add spatial extensions
CREATE EXTENSION postgis_topology;
-- CREATE SCHEMA postgis;

CREATE table staging."Daily Log" -- This is to store important daily metrics
    ("date" date DEFAULT CURRENT_DATE,
     new_users int,
     messages_sent int DEFAULT 0,
     segments_sent int DEFAULT 0,
	 reports_for_day int DEFAULT 0
    );

CREATE table staging."Sign Up Information"-- This is our staging record keeping for users
	(record_id integer, -- Unique Identifier from REDCap
	last_messaged timestamp DEFAULT CURRENT_DATE + INTERVAL '8 hours', -- Last time messaged
	messages_sent int DEFAULT 1, -- Number of messages sent
	active_alerts bigint [] DEFAULT array[]::bigint [], -- List of Active Alerts
	cached_alerts bigint [] DEFAULT array[]::bigint [], -- List of ended Alerts not yet notified about
	subscribed boolean DEFAULT TRUE, -- Is the user wanting texts? 
	geometry geometry);
	
CREATE INDEX user_gid ON staging."Sign Up Information" USING GIST(geometry);  -- Create spatial index
	
CREATE table staging."Reports Archive"-- These are for reporting to the City and future research
	(report_id varchar(12), -- Unique Identifier with format #####-MMDDYY
	start_time timestamp,
	duration_minutes integer,
	max_reading float, 
	sensor_indices int [], -- List of Sensor Unique Identifiers
	alert_indices bigint [] -- List of Alert Identifiers
    );
    
CREATE TABLE staging."Afterhour Reports" -- Storage for messages informing of an alert that ended overnight
    (
    record_id integer, -- Unique Identifier from REDCap
    message text
    );

CREATE table staging."Active Alerts Acute PurpleAir"
	(alert_index bigserial, -- Unique identifier for an air quality spike alert
	 sensor_indices int [] DEFAULT array[]::int [], -- List of Sensor Unique Identifiers 
	  start_time timestamp,
	   max_reading float); -- Maximum value registered from all sensors

CREATE table staging."Archived Alerts Acute PurpleAir" -- Archive of the Above table
    (alert_index bigint,
    sensor_indices int [], -- List of Sensor Unique Identifiers 
    start_time timestamp,
    duration_minutes integer,
    max_reading float);
    
CREATE TABLE staging."PurpleAir Stations" -- See PurpleAir API - https://api.purpleair.com/
(
	sensor_index int,
	date_created timestamp,
	last_seen timestamp,
	last_elevated timestamp DEFAULT TIMESTAMP '2000-01-01 00:00:00',
	"name" varchar(100),
	position_rating int,
	channel_state int,
	channel_flags int,
	altitude int,
	geometry geometry
);

CREATE INDEX PurpleAir_gid ON staging."PurpleAir Stations" USING GIST(geometry);  -- Create spatial index for stations

CREATE TABLE staging."Minneapolis Boundary"-- From MN Geocommons - https://gisdata.mn.gov/dataset/us-mn-state-metc-bdry-census2020counties-ctus
(
    "CTU_ID" int, -- Unique Identifier
    "CTU_NAME" text, -- City/Township Name
    "CTU_CODE" text, -- City/Township Code
    "xmin" double precision, -- coordinate values
		"ymin" double precision, -- coordinate values
		"xmax" double precision, -- coordinate values
		"ymax" double precision -- coordinate values
); 

INSERT TABLE staging."Minneapolis Boundary"
	("CTU_ID", "CTU_NAME", "CTU_CODE")
	VALUES
		('2395345','Minneapolis', '4300','-93.33037537752216', '44.88968834134478', '-93.19306250738248','45.05214646628739')