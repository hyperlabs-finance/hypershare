1. Merge Holders, Holders Delegates and Holders Frozen into a single HypershareRegister contract

2. Ensure these fields are accesible in or via the HypershareRegister contract: Name, Address, Share class, Number of shares, Amount paid for shares, Date person was registered as a member, Date person ceased to be registered as a member

3. Other contracts needed:
	Factory - deploy the entire suite
	Agreement signer - sign an agreement and receive shares
	Side letter - sign an agreement at point of sale that 
	Burner - burn and re-issue shares, i.e. burn token 1 (share type A) and reissue share token 2 (share type B)
	Dividend? 