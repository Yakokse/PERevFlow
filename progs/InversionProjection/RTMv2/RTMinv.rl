(Start Final Rules S_right) -> (Start Final Rules S_right) with (Q Q1 Q2 S1 S2 S S_left RulesRev Rule R)

init:
	from act1
	Q ^= Start
	S ^= 'BLANK
	exit

act1:
	fi ((R = 'LEFT) || (R = 'RIGHT))
		from shft
		else symbol
	Rule <- (Q1 . (R . Q2))
	Rules <- (Rule . Rules)
	if (!(RulesRev) && (Q = Start))
		goto init
		else act3

act2:
	fi Rules
		from act3
		else reload
	(Rule . RulesRev) <- RulesRev
	(Q1 . (R . Q2)) <- Rule
	if ((R = 'LEFT) || (R = 'RIGHT))
		goto shft3
		else symbol2

reload:
	fi RulesRev
		from reload
		else act3
	(Rule . Rules) <- Rules
	RulesRev <- (Rule . RulesRev)
	if Rules
		goto reload
		else act2

act3:
	fi (!(RulesRev) && (Q = Final))
		from stop
		else act1
	if !(RulesRev)
		goto reload
		else act2

stop:
	entry
	S ^= 'BLANK
	Q ^= Final
	goto act3

symbol:
	fi ((Q = Q1) && (S = S1))
		from symbol1
		else symbol2
	R <- (S1 . S2)
	goto act1

symbol1:
	from symbol2
	S ^= S2
	S ^= S1
	Q ^= Q2
	Q ^= Q1
	goto symbol

symbol2:
	from act2
	(S1 . S2) <- R
	if ((Q = Q2) && (S = S2))
		goto symbol1
		else symbol

shft:
	fi (Q = Q1)
		from shft1
		else shft3
	goto act1

shft1:
	fi (R = 'LEFT)
		from left
		else right
	Q ^= Q2
	Q ^= Q1
	goto shft

left:
	fi ((S_right = 'nil) && (S = 'BLANK))
		from left_1b
		else left_1p
	goto shft1

left_1b:
	from left1
	S ^= 'BLANK
	goto left

left_1p:
	from left1
	(S . S_right) <- S_right
	goto left

left1:
	fi (S_left = 'nil)
		from left_2b
		else left_2p
	if (S_right = 'nil)
		goto left_1b
		else left_1p

left_2b:
	from left2
	S ^= 'BLANK
	goto left1

left_2p:
	from left2
	S_left <- (S . S_left)
	goto left1

left2:
	from shft2
	if ((S_left = 'nil) && (S = 'BLANK))
		goto left_2b
		else left_2p

right:
	fi ((S_left = 'nil) && (S = 'BLANK))
		from right_1b
		else right_1p
	goto shft1

right_1b:
	from right1
	S ^= 'BLANK
	goto right

right_1p:
	from right1
	(S . S_left) <- S_left
	goto right

right1:
	fi (S_right = 'nil)
		from right_2b
		else right_2p
	if (S_left = 'nil)
		goto right_1b
		else right_1p

right_2b:
	from right2
	S ^= 'BLANK
	goto right1

right_2p:
	from right2
	S_right <- (S . S_right)
	goto right1

right2:
	from shft2
	if ((S_right = 'nil) && (S = 'BLANK))
		goto right_2b
		else right_2p

shft2:
	from shft3
	if (R = 'LEFT)
		goto left2
		else right2

shft3:
	from act2
	if (Q = Q2)
		goto shft2
		else shft
