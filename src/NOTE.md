Hypercore is the generalised extension interface that uses the diamond pattern.

All Hypercores are extensions of the underlying contract and executed in Hypershare rather than externally.

It allows Hypercores to use internal functions such as _mint()

It also allows Hypercores to implement an array of functions that are callable via the Hypershare contract rather having to be called directly.

However, the before and after token hooks still apply. Hypercore functions must be appropriately bundled so that for example, using callHypercore, the shareholder registry is not upgraded twice.

The Hypershare factory features a means of deploying and adding Hypercore to a share contract. 

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

Create a hook/interface for services so that services actions can be pre-validated with services, like ERC1155 receiver hook
Allows decentralised services to create a trustless environment by using hooks?