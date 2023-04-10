import pytest
from brownie import accounts, Contract, Hypershare, HypershareRegistry 

ZERO_ADDR = "0x0000000000000000000000000000000000000000"
PAYEE1 = accounts[1]
PAYEE2 = accounts[2]
PAYEE3 = accounts[3]
PAYEE4 = accounts[4]

def main():
		
	# Deploy the  contract
	HYPERSHARE = Hypershare.deploy(
		"https://token-uri.com",
        ZERO_ADDR,
        ZERO_ADDR,
		{"from": accounts[0]}
	)
	print(HYPERSHARE.address)
	
	REGISTRY = HypershareRegistry.deploy(
        HYPERSHARE.address,
        ZERO_ADDR,
		{"from": accounts[0]}
	)
	print(REGISTRY.address)

	tx = HYPERSHARE.setRegistry(REGISTRY.address)
	# tx.wait(1)

	tx = HYPERSHARE.newToken(
		#shareholderLimit 
		10,
		#shareholdingMinimum
		5000000000000000000,
		#shareholdingNonDivisible
		True
	)
	# tx.wait(1)

	tx = HYPERSHARE.mintBatch(
		# accounts
		[PAYEE1, PAYEE2, PAYEE3, PAYEE4],
		# id
		0,
		# amount
		[100, 200, 300, 400],
		# data
		"mint"
	)