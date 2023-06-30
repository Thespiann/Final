CREATE TABLE IF NOT EXISTS team (
		name varchar(20) not null primary key,
		arena varchar(30) not null ,
		description text,
		home_wins smallint not null,
		away_wins smallint not null,
		home_losses smallint not null,
		away_losses smallint not null,
		home_draws smallint not null,
		away_draws smallint not null);
		
CREATE TABLE IF NOT EXISTS player (
    name varchar(10) NOT NULL,
    last_name varchar(10) NOT NULL,
    team varchar(20) NOT NULL REFERENCES team(name),
    player_position varchar(20) NOT NULL,
    id serial PRIMARY KEY
);
--checking for players to not be more than 11

CREATE OR REPLACE FUNCTION check_max_players()
    RETURNS TRIGGER AS $$
BEGIN
    IF (
        SELECT COUNT(*)
        FROM player
        WHERE team = NEW.team
    ) = 11 THEN
        RAISE EXCEPTION 'Maximum number of players per team cannot be exceeded';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_max_players
BEFORE INSERT OR UPDATE ON player
FOR EACH ROW
EXECUTE FUNCTION check_max_players();

create table if not exists manager(
		name varchar(10) not null ,
		last_name varchar(10) not null,
		team varchar(20) not null references team(name),
		past_position varchar(20) not null,
		total_minutes int,
		id serial primary key);

CREATE TABLE IF NOT EXISTS match (
    home_team varchar(20) NOT NULL REFERENCES team (name),
    visiting_team varchar(20) NOT NULL REFERENCES team (name),
    home_score smallint NOT NULL,
    visiting_score smallint NOT NULL,
    date date NOT NULL,
    total_duration smallint NOT NULL,
    id serial PRIMARY KEY,
    CONSTRAINT unique_home_team UNIQUE (date, home_team),
	CONSTRAINT unique_visiting_team UNIQUE (date, visiting_team)
);
--checking for minimum 10 days in between matches
CREATE OR REPLACE FUNCTION check_min_days()
    RETURNS TRIGGER AS $$
DECLARE
    min_date date;
    max_date date;
BEGIN
    SELECT date - INTERVAL '10 days', date + INTERVAL '10 days'
    INTO min_date, max_date-- the date a match could happen is this date -10 days and the max date a match could happen is this match date +10
    FROM match
    WHERE home_team = NEW.home_team OR visiting_team = NEW.home_team OR --i check for both visiting teams and home teams
          home_team = NEW.visiting_team OR visiting_team = NEW.visiting_team;

    IF min_date IS NOT NULL AND NEW.date >= min_date AND NEW.date <= max_date THEN-- if i have a match for this team before the new one im adding, i check the dates 
        RAISE EXCEPTION 'Minimum days between matches not satisfied';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_min_days
BEFORE INSERT OR UPDATE ON match
FOR EACH ROW
EXECUTE FUNCTION check_min_days();

CREATE TABLE IF NOT EXISTS game_event(
   	event_type varchar(30) not null,
   	player_id integer not null references player(id)  ,
   	match_id integer not null references match(id),
   	event_time time not null,
   	id serial primary key);
		
CREATE TABLE IF NOT EXISTS minutes_per_match(
	duration integer not null,
	player_id integer not null references player(id),
	match_id integer not null references match(id),
	id serial primary key);


--function to insert manager using user:
CREATE OR REPLACE FUNCTION promote_to_manager(player_id INT)
RETURNS VOID AS $$
DECLARE
    total_minutes INTEGER;
BEGIN
    -- Calculate the total_minutes
    SELECT COALESCE(SUM(duration), 0)
    INTO total_minutes
    FROM minutes_per_match
    WHERE player_id = player_id;

    -- Insert into the manager table
    INSERT INTO manager (name, last_name, team, past_position, total_minutes)
    SELECT name, last_name, team, player_position, total_minutes
    FROM player
    WHERE id = player_id;

    -- Delete from the player table
    DELETE FROM player WHERE id = player_id;
END;
$$ LANGUAGE plpgsql;
