--Ερώτημα 2α
SELECT manager.name , manager.last_name
FROM manager
JOIN team ON team.name=manager.team
JOIN match ON (team.name=match.home_team )--ή θα μπορούσε να είναι : team.name=match.visiting_team
WHERE match.id=3

--Ερώτημα 2β
SELECT game_event.event_type, game_event.event_time, player.name AS player_name
FROM game_event
JOIN player ON game_event.player_id = player.id
JOIN match on game_event.match_id = match.id
WHERE match.id = '5' AND (game_event.event_type = 'goal' OR game_event.event_type = 'penalty kick');

--Ερώτημα 2γ
select p.id as player_id,p.name as player_first_name, p.last_name as player_last_name, p.team,p.player_position, m.id as match_id,min.duration as minutes_per_player_per_match,
	CASE WHEN game_events.match_id =m.id and game_events.player_id=p.id THEN game_events.event_type ELSE NULL END AS event_type
	from player p
	join match m on p.team=m.home_team or p.team=m.visiting_team
	join minutes_per_match min on min.player_id=p.id and min.match_id=m.id
	left join game_event game_events on game_events.player_id=p.id
	where m.id IN (
    SELECT match.id
    FROM match
    WHERE EXTRACT(YEAR FROM match.date) = 2023) and p.id = 3 order by m.id ;


--Ερώτημα 2δ
SELECT Occasion, Performance_Of_Team
FROM (
  SELECT 'Total Matches: ' AS Occasion, (SELECT COUNT(*) FROM match WHERE ((home_team = 'AEK' OR visiting_team = 'AEK') 
										AND (match.date >= '01-01-2023' AND match.date <= '12-30-2023')))
 										AS Performance_Of_Team, 1 AS Order_Num

  UNION

  SELECT 'Home Matches: ', (SELECT COUNT(*) FROM match WHERE home_team = 'AEK' AND (match.date >= '01-01-2023' AND match.date <= '12-30-2023')), 2

  UNION

  SELECT 'Away Matches: ', (SELECT COUNT(*) FROM match WHERE visiting_team = 'AEK' AND (match.date >= '01-01-2023' AND match.date <= '12-30-2023')), 3

  UNION

  SELECT 'Total Wins: ', (SELECT SUM(home_wins + away_wins) FROM team WHERE name = 'AEK'), 4

  UNION

  SELECT 'Total Losses: ', (SELECT SUM(home_losses + away_losses) FROM team WHERE name = 'AEK'), 5

  UNION

  SELECT 'Total Draws: ', (SELECT SUM(home_draws + away_draws) FROM team WHERE name = 'AEK'), 6

  UNION

  SELECT 'Home Wins: ', (SELECT home_wins FROM team WHERE name = 'AEK'), 7

  UNION

  SELECT 'Home Losses: ', (SELECT home_losses FROM team WHERE name = 'AEK'), 8

  UNION

  SELECT 'Home Draws: ', (SELECT home_draws FROM team WHERE name = 'AEK'), 9

  UNION

  SELECT 'Away Wins: ', (SELECT away_wins FROM team WHERE name = 'AEK'), 10

  UNION

  SELECT 'Away Losses: ', (SELECT away_losses FROM team WHERE name = 'AEK'), 11

  UNION

  SELECT 'Away Draws: ', (SELECT away_draws FROM team WHERE name = 'AEK'), 12
	
) AS sub
ORDER BY Order_Num;
