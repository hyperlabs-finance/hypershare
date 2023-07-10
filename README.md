# Hypershare

**Welcome to Hypershare: an ERC1155-based multi-token share contract, shareholder registry and compliance suite.**

Hypershare is a toolkit for asset tokenisation, allowing entrepreneurs to create and manage tokenised equity, automate compliance and raise venture funding. For investors, Hypershare provides a platform to realise unprecedented liquidity on assets that would have previously been immobile, enabling equity shares to be traded like any other crypto asset.

## Hypershare.sol

Hypershare is an ERC1155 based tokenised equity contract. It provides all the functions traditionally associated with an ERC1155 token contract, plus additional issuer controls designed (and legally required in some jurisdictions) to support for equity shares. These features include forced transfers and share recovery in the event that a shareholder has lost access to their wallet.

## HypershareCompliance.sol

HypershareCompliance works in tandem with Hypershare and the HyperbaseClaimRegistry, recording which attributes a prospective shareholder must have in order to receive shares. These attributes are known as claims. Unless a user is whitelisted, when a share transfer is initiated the HypershareCompliance contract iterates through the necessary claims, comparing them against the claims held by the prospective shareholder in the HyperbaseClaimRegistry. 

## HypershareRegistry.sol

HypershareRegistry keeps an on-chain record of the shareholders of its corresponding Hypershare contract. It then uses this record to enforce limit-based compliance checks, such as ensuring that a share transfer does not result in too many shareholders, fractional shareholdings or  that a shareholder has not been frozen by the owner-operator.