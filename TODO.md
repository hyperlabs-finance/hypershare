<!-- 1. Merge Holders, Holders Delegates and Holders Frozen into a single HypershareRegister contract -->

2. Error messages and requires as modifiers

3. Ensure these fields are accessible in or via the HypershareRegister contract: Name, Address, Share class, Number of shares, Amount paid for shares, Date person was registered as a member, Date person ceased to be registered as a member

4. Restructure the voting contract so that it can be used to annex HyperDAO or as a standalone voting contract for off-chain votes. 

5. Other contracts for the suite:
	Factory - deploy the entire suite
	Agreement signer - sign an agreement and receive shares
	Side letter - sign an agreement at point of sale 
	Burner - burn and re-issue shares, i.e. burn token 1 (share type A) and reissue share token 2 (share type B)
	Weighted voting - create contract for weighted voting by share type and non-participation by share type
	Dividend splitter - 
	Direct sale contract - 1 to 1 sale contract