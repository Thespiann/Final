CREATE VIEW match_schedule AS
SELECT thismatch.date AS match_date,
       thismatch.total_duration AS duration,
       home_team.arena AS arena,
       thismatch.home_team AS home_team_name,
       thismatch.visiting_team AS visiting_team_name,
       thismatch.home_score,
       thismatch.visiting_score,
       thismatchplayer.name || ' ' || thismatchplayer.last_name AS player_name,
       thismatchplayer.player_position,
       minutes.duration AS player_duration,
       CASE WHEN game_events.player_id = thismatchplayer.id THEN game_events.event_type ELSE NULL END AS event_type,
       CASE WHEN game_events.player_id = thismatchplayer.id THEN game_events.event_time ELSE NULL END AS event_time
FROM match thismatch
JOIN team home_team ON home_team.name = thismatch.home_team
JOIN team visiting_team ON visiting_team.name = thismatch.visiting_team
JOIN player thismatchplayer ON thismatchplayer.team = thismatch.home_team OR thismatchplayer.team = thismatch.visiting_team
LEFT JOIN game_event game_events ON game_events.match_id = thismatch.id AND game_events.player_id = thismatchplayer.id
JOIN minutes_per_match minutes ON minutes.match_id = thismatch.id AND minutes.player_id = thismatchplayer.id
WHERE thismatch.date = '2021-04-08';

CREATE VIEW league_matches AS
SELECT thismatch.total_duration AS duration,
       home_team.arena AS arena,
       thismatch.home_team AS home_team_name,
       thismatch.visiting_team AS visiting_team_name,
       thismatch.home_score,
       thismatch.visiting_score
FROM match thismatch
JOIN team home_team ON home_team.name = thismatch.home_team
WHERE thismatch.date>='2023-01-01' AND thismatch.date<='2023-12-30';
