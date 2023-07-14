Hypercore is the generalised extension interface.

Hypercores are added to Hypershare and called in the before/after hook ~ ensure that before/after hook is being called as part of internal _safeTransfer so that it is being updated in forced transfers.

Extensions:
	Registry
	Compliance 
	Delegates
	
	Scrip
		Minimal proxy erc20 factory

	Signer
	SAFT/SAFE/SAFTE/SAFET?
	Direct sale
	Crowd sale
	Vesting


A wrapper for all sales transactions
Also, review equities law, see if neccesary to reg in the same contract

Factory must provide way of selecting and adding Hypercores

Access control in the Hypershare contract divided by token id. Caller passed in as the operator and used to update the Hypercore, for example 

Create a hook/interface for services so that services actions can be pre-validated with services, like ERC1155 receiver hook
Allows decentralised services to create a trustless environment by using hooks.