-- gentest.t
--
-- a test to compare terra to python

function nested_loops_way(teams)
	local best_player = teams[1].roster[1]
	for teamidx, team in ipairs(teams) do
		for playeridx, player in ipairs(team.roster) do
			if player.career_hits > best_player.career_hits then
				best_player = player
			end
		end
	end
	return best_player
end

function makePlayer()
	local player = {}
	player.name = "Player " .. math.random()
	player.career_hits = math.random()
	return player
end

function makeTeam(nplayers)
	local team = {}
	team.roster = {}
	for i = 1,nplayers do
		table.insert(team.roster, makePlayer())
	end
	return team
end

test_teams = {}
num_players = 11
for i = 1,10 do
	table.insert(test_teams, makeTeam(num_players))
end

starttime = os.clock()
for i = 1,100000 do
	best_player = nested_loops_way(test_teams)
end
deltatime = os.clock() - starttime
print("took " .. deltatime .. " s")
print(best_player.name .. ": " .. best_player.career_hits)