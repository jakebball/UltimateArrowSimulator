return {
	["olreliable"] = {
		displayName = "Ol' Reliable",
		description = "This raggedy shooting range may not be the prettiest, but it does it's job",
		previousRange = "test",
		enemyKillRequirement = 50,

		enemies = {
			[1] = "scarecrow",
		},

		rewards = {
			tokenRarityTable = {
				{ name = "basic", weight = 1 },
			},

			tokenGradeTable = {
				{ name = "50Grade", weight = 1 },
			},
		},
	},
}
