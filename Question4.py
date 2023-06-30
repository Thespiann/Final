import psycopg2

# Connecting to our db
conn = psycopg2.connect(
    host="localhost",
    database="Final",
    user="postgres",
    password="root"
)

cur = conn.cursor()

# Function 
def execute_query(query):
     # Setting the datestyle to 'ISO, MDY' for queries that use date
    cur.execute("SET datestyle = 'ISO, MDY'")
    cur.execute(query)
    results = cur.fetchall()
    for row in results:
        print(row)

while True:
    # Ask the user for input
    print("Select a query to run:")
    print("1. Query 2α")
    print("2. Query 2β")
    print("3. Query 2γ")
    print("4. Query 2δ")
    print("0. Exit")

    user_choice = input("Enter the number of the query (or 0 to exit): ")

    if user_choice == "0":
        # Exit the program
        break
    elif user_choice == "1":
        query = "SELECT manager.name, manager.last_name FROM manager JOIN team ON team.name=manager.team JOIN match ON (team.name=match.home_team) WHERE match.id=3"
    elif user_choice == "2":
        query = "SELECT game_event.event_type, game_event.event_time, player.name AS player_name FROM game_event JOIN player ON game_event.player_id = player.id JOIN match ON game_event.match_id = match.id WHERE match.id = '5' AND (game_event.event_type = 'goal' OR game_event.event_type = 'penalty kick')"
    elif user_choice == "3":
        query = "SELECT p.id AS player_id, p.name AS player_first_name, p.last_name AS player_last_name, p.team, p.player_position, m.id AS match_id, min.duration AS minutes_per_player_per_match, CASE WHEN game_events.match_id = m.id AND game_events.player_id = p.id THEN game_events.event_type ELSE NULL END AS event_type FROM player p JOIN match m ON p.team = m.home_team OR p.team = m.visiting_team JOIN minutes_per_match min ON min.player_id = p.id AND min.match_id = m.id LEFT JOIN game_event game_events ON game_events.player_id = p.id WHERE m.id IN (SELECT match.id FROM match WHERE EXTRACT(YEAR FROM match.date) = 2023) AND p.id = 3 ORDER BY m.id"
    elif user_choice == "4":
        query = "SELECT Occasion, Performance_Of_Team FROM (SELECT 'Total Matches: ' AS Occasion, (SELECT COUNT(*) FROM match WHERE ((home_team = 'AEK' OR visiting_team = 'AEK') AND (match.date >= '2023-01-01' AND match.date <= '2023-12-30'))) AS Performance_Of_Team, 1 AS Order_Num UNION SELECT 'Home Matches: ', (SELECT COUNT(*) FROM match WHERE home_team = 'AEK' AND (match.date >= '01-01-2023' AND match.date <= '12-30-2023')), 2 UNION SELECT 'Away Matches: ', (SELECT COUNT(*) FROM match WHERE visiting_team = 'AEK' AND (match.date >= '01-01-2023' AND match.date <= '12-30-2023')), 3 UNION SELECT 'Total Wins: ', (SELECT SUM(home_wins + away_wins) FROM team WHERE name = 'AEK'), 4 UNION SELECT 'Total Losses: ', (SELECT SUM(home_losses + away_losses) FROM team WHERE name = 'AEK'), 5 UNION SELECT 'Total Draws: ', (SELECT SUM(home_draws + away_draws) FROM team WHERE name = 'AEK'), 6 UNION SELECT 'Home Wins: ', (SELECT home_wins FROM team WHERE name = 'AEK'), 7 UNION SELECT 'Home Losses: ', (SELECT home_losses FROM team WHERE name = 'AEK'), 8 UNION SELECT 'Home Draws: ', (SELECT home_draws FROM team WHERE name = 'AEK'), 9 UNION SELECT 'Away Wins: ', (SELECT away_wins FROM team WHERE name = 'AEK'), 10 UNION SELECT 'Away Losses: ', (SELECT away_losses FROM team WHERE name = 'AEK'), 11 UNION SELECT 'Away Draws: ', (SELECT away_draws FROM team WHERE name = 'AEK'), 12) AS sub ORDER BY Order_Num"
    else:
        print("Invalid choice. Please try again.")
        continue

    # Execute the query
    execute_query(query)

# Close the cursor and connection
cur.close()
conn.close()
