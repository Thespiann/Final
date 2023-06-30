CREATE TABLE downgraded_team (
    name VARCHAR,
    arena VARCHAR,
    description VARCHAR,
    home_wins INTEGER,
    away_wins INTEGER,
    home_losses INTEGER,
    away_losses INTEGER,
    home_draws INTEGER,
    away_draws INTEGER
);
CREATE OR REPLACE FUNCTION downgrade_team(team_to_downgrade VARCHAR)
RETURNS VOID AS $$
BEGIN
    -- Delete rows from tables that reference the team to downgrade
	DELETE FROM game_event WHERE player_id IN (select player.id from player where player.team=team_to_downgrade);
	DELETE FROM game_event WHERE match_id IN (select match.id from match where (match.home_team=team_to_downgrade or match.visiting_team=team_to_downgrade));
	DELETE FROM minutes_per_match WHERE player_id IN (select player.id from player where player.team=team_to_downgrade);
	DELETE FROM minutes_per_match WHERE match_id IN (select match.id from match where (match.home_team=team_to_downgrade or match.visiting_team=team_to_downgrade));
	DELETE FROM match where (home_team=team_to_downgrade or visiting_team=team_to_downgrade);
	DELETE FROM manager WHERE team = team_to_downgrade;
    DELETE FROM player WHERE team = team_to_downgrade;
	
    -- Insert team into downgraded_team
    INSERT INTO downgraded_team (name, arena, description, home_wins, away_wins, home_losses, away_losses, home_draws, away_draws)
    SELECT name, arena, description, home_wins, away_wins, home_losses, away_losses, home_draws, away_draws
    FROM team
    WHERE name = team_to_downgrade;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION downgrade_team_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM downgrade_team(OLD.name);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER downgrade_team_trigger
BEFORE DELETE ON team
FOR EACH ROW
EXECUTE FUNCTION downgrade_team_trigger_function();
