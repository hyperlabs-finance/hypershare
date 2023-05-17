# Hypershare

**Welcome to Hypershare: an ERC1155-based multi-token share contract, shareholder registry and compliance suite.**

## What is Hypershare?

Hypershare is a toolkit for asset tokenisation, allowing entrepreneurs to create and manage tokenised equity, automate compliance and raise venture funding. For investors, Hypershare provides a platform to realise unprecedented liquidity on assets that would have previously been immobile, enabling equity shares to be traded like any other crypto asset.

Hypershare harnesses trustlessness and governs interactions between parties, allowing value to flow more efficiently. By creating a shared language for describing equity investments and other tokenized assets we can standardise interactions allowing people and organisations to work together in ways that would never before have been possible.

# Hypershare
In the same way that physical systems converge toward the path of least resistance, users naturally tend toward the solutions that offer the greatest convenience. For this reason, unlike our competitors, we have chosen to separate the notion of equity tokenisation from equity token offerings (“ETOs”).

Asset tokenisation offers an array of benefits over contemporary solutions. However, it is by no means a simple process. Token issuance is still dependent on an array of actors such as advisors, law firms, broker-dealers, KYC/AML providers, custody agents, cap table management solutions, and more. Much like conventional crowdfunding campaigns, what is often perceived as a simple, effective form of alternative funding comes with its own set of drawbacks and considerations.

While the concepts of equity tokens and equity token sales are highly interrelated, they are not mutually dependent. Whereas token sales are reliant on tokenisation of the underlying asset, tokenisation does not demand a blockchain-based public offering as its primary distribution method. ETOs may not be necessary nor appropriate for many users and introduce an array of additional regulatory and legal considerations that increase cost and complexity significantly.

In our opinion, there has not been a product that has fully realised the potential of tokenised equity. It is our belief that tokenised equity as a mature, digital-native asset is more than viable as a standalone product. For this reason Hypershare primarily targets private, primary market transactions between issuers and accredited investors. By removing ETOs from the core product offering, issuing digital equity requires very little behavioural change or commitment on the part of users. Whereas tokenisation could easily take several months from end-to-end, without the regulatory and legal concerns that accompany large public crowd sales, issuers may start to see the benefits within as little as half an hour.

Part of what makes Hypershare’s value offering so compelling is that it is so simple. Instead of manually sharing legal agreements in PDF form, signing them physically or with something like DocuSign, manually updating the shareholder register and issuing share certificates, Hypershare provides a toolset for both issuers and investment professionals to streamline their legal, administrative, and transactional activities into a single, integrated process. In this regard, Hypersurface creates a new digital utility, much like email or file sharing. One that we hope both issuers and investors will come to use on a daily basis.

The key distinction between Hypersurface and contemporary equity management solutions is that rather than using disconnected private records, Hypersurface makes use of the blockchain to create a synchronised record of ownership. One that is open, composable and can be integrated immediately by other actors in the ecosystem. With ownership and transaction infrastructure secured by the blockchain, information is rendered and available to read and write by anyone with appropriate permissions. This may be a shareholder transferring shares or a third-party application.

Open, standardised protocols have been instrumental in the development of many platforms, such as the web. In the same way that a currency is only valuable in that it is a widely recognised means of exchange, the more broadly digital equity assets are recognised the more valuable we believe they will become. With this in mind, Hypersurface equity tokens have been developed under the ERC-1155 multi-token standard and come ready to integrate with an entire ecosystem of applications out of the box.

From instant equity-backed loans to secondary markets trading and digital voting, the blockchain opens up a whole host of new and exciting use cases. While both analogue and digital equity may represent an equal stake in the underlying venture, digital equity has far greater use value and has greatly enhanced transferability. For this reason, we anticipate the value of Hypersurface digital equity to be greater than its analogue counterpart, and to increase significantly over time as more resources become available.

For a process that takes as little as half an hour, we see this as potentially the easiest way for an issuer to increase the value of an asset and the appeal of an investment opportunity.

### Tokenisation Process
1. Structuring
Configure the basic details of the asset by defining its name, ticker, supply and more. Structure the asset type and build the legal agreement from a library of modules.

2. Compliance
Define the compliance rules for the asset. This includes total holder limits, non-divisibility, non-transferability, and more. Any whitelisted addresses are exempt, otherwise, compliance rules are enforced at the protocol level.

3. Creation
Key information is encoded in a digital format. The token is deployed on the blockchain. Legal agreements are uploaded to IPFS.

4. Distribution
Invite and issue shares via a private invite link. Investors can create an account in a few simple clicks, review and cryptographically sign digital legal agreements and receive their shares. All in a single, integrated workflow.

5. Management
The shareholder register is automatically rendered and updated. This on-chain record may serve as the definitive record of a company's shareholders or can be exported to an offline shareholder register. If issuers need to take action they have a suite of tools such as recovery, force transfers and freezing.

# Regulatory Requirements
One of the most important attributes of equity tokens, as compared to utility or exchange tokens, is that they are subject to existing securities laws. Therefore any design must make remain compliant with legal and statutory requirements. Furthermore, such a solution should provide issuers with a number of fine-grain controls. We identify a number of key attributes for equity tokens:

1. Be upgraded without changing the token smart contract address.
2. Implement multiple tokens in a single smart contract.
3. Embed legal agreements in a way that is secure and legally binding.
4. Apply any rule of compliance that is required by the token issuer or regulator.
5. Have a standard interface to pre-check if a transfer is going to pass or fail.
6. Provide an up-to-date list of token holders.
7. Have a recovery system in case an investor loses access to their account.
8. Be able to freeze tokens in a shareholder's wallet, partially or fully.

## Multi-token
The goal of Hypershare is to enable the issuance of equity in a way that is secure, compliant, and frictionless for users. As the ERC-20 standard was developed for standalone assets any ERC-20-derived security token would require multiple redeployments of the same contract for each and every new asset, with little to no change between implementations. Needless to say, this is both inefficient and resource-intensive, particularly for use cases such as alphabet shares. Numerous disparate token implementations also pose a security risk and increase confusion for users.

Unlike other permissioned tokens, at its core Hypershare uses the ERC-1155 multi-token standard. While the ERC-20 requires a new and distinct smart contract for each token implementation, the ERC-1155 uses a single smart contract to implement an arbitrary amount of tokens at once. When a new token is “created” a unique identifier is added to the list of tokens contained within the contract. This identifier supplements the unique contract address associated with ERC-20 token implementations. Accordingly, the ERC-1155 features an additional function argument id as the unique identifier for each token. Although the contract is shared between multiple tokens the accounting for each token, operator controls, and compliance controls are kept separate. This approach leads to significant gas savings as compared to that used by the ERC-20 standard, allowing issuers to create new assets at a fraction of the cost and complexity.

## Compliance Controls
A unique feature of Hypershare is that it enforces compliance at the protocol level. Unlike the ERC-20, where token transfers only fail due to the user having inadequate funds, Hypershare transactions can fail for a variety of reasons. These include the receiver not having verified KYC information, assets having been locked or frozen, and economic and jurisdictional constraints such as shareholder, acquisition, and geographic limits. Somewhat counterintuitively, we believe that stronger transfer controls will increase asset transferability as without them (a) regulators will not permit large-scale tokenisation of regulated assets and (b) issuers will not support automatic transfer resolution on-chain.

## Advanced Issuer Controls
Hypershare features a number of advanced issuer controls designed to facilitate effective and secure equity tokenisation. In order to do so it is essential that issuers have options such as freezing assets, partially freezing assets, force transferring assets, and recovering assets for holders. To this end, Hypershare introduces a number of new functions allowing issuers to perform actions, including:

● pause/unpause
● recover
● unfreezePartialShares/freezePartialShares
● batchFreezePartialShares/batchUnfreezePartialShares
● setAddressFrozen
● batchSetAddressFrozen

## Upgradability
Hypershares’ functional logic may well see numerous upgrades throughout a company's life. To support upgradability, token accounting is separated from the underlying logic. This means that the overall state is maintained between upgrades.

## Non-divisible Shares

Non-divisible shares introduce significant usability errors, particularly for services that are reliant on divisible fees, such as liquidity pools. Previous approaches to non-divisible shares simply set the token to zero decimal places, as opposed to the conventional eighteen. The issue is this change is hard to reverse once tokens are released. To support non-divisible shares Hypersurface enforces non-divisible token transfers. If a transfer creates divisible shares it will fail. This means that non-divisibly tokens can be set to divisible should the operator so choose.

## Metadata

In order to give on-chain representation to real-world legal agreements, and do so in a way that is legally and cryptographically binding, the equity token contract must give equal precedent to legal agreements and the corresponding metadata. Hypershare makes use of the ERC-1155’s metadata URI to attach a structured JSON legal schema that provides information about the underlying agreement in a machine-readable format. For more information see regarding asset metadata see Hyperframe: Hyperlabs solution to a machine-readable legal system.  

## Share Register

Hypersurface creates a share register with the primary proof of ownership maintained and updated directly on the blockchain. Each share in the share register is represented by an equity token, providing an immutable and secure record of shareholdings and transaction histories. Instead of requiring manual documentation and calculation the share register is automatically calculated and updated on each transfer. To remain compliant the share register must meet the requirements of a traditional share register. Although there are minor changes across jurisdictions, the fields typically that must be recorded are:

● Name
● Address
● Share class
● Number of shares
● Amount paid for shares
● Date person was registered as a member
● Date person ceased to be registered as a member

We believe that Hypersurface’s share register alone provides significant benefits over current register administration tools and methodologies by reducing inefficiency, overheads, and inaccuracy, ultimately providing companies with a more effective platform to comply with statutory obligations. As the share register can interface with external machine systems there is scope to further automate the process to provide a platform that automatically submits the necessary fillings when a transfer takes place.

## Compliance

Each and every transfer of Hypershare tokens is coupled with an on-chain validator system. The compliance smart contracts record and enforce transfer controls, ensuring that the transfer and recipient are eligible. Compliance can be used to define and enforce a variety of controls such as accepted countries, the maximum number of investors per country, the maximum number of shares per holder, the accreditation status of the holder and more.

The compliance contracts then read the properties of the asset and interacting identities to enforce certain behaviours, either returning true or false based on the eligibility status of the transfer. When a transfer is made the token contract makes a function call to the compliance contracts to verify the eligibility of (a) the transfer and (b) the receiver. The compliance contracts enforce logic that will check the parameters of the token itself such as holder limits and the claims of the receiver's account. Should all requirements be met the compliance contracts will return true approving the transfer, or false otherwise.

The compliance contracts provide an open, programmable means of automating compliance, shifting much of the burden away from users and onto the protocol. This greatly aids in increasing transferability, as in combination with the Hyperbase identity, system much of the menial work of validating KYC and other credentials can be eliminated entirely. For its initial release, Hypersurface is targeting a set of rules and transfer controls that are universally applicable. However, as the protocol grows we hope to be able to add further detail to the compliance contracts, implementing new rules in accordance with jurisdictional requirements. With the development of compliance contracts, we expect to see the emergence of greatly increased liquidity.

### HypershareRegistry
The HypershareRegistry records share ownership and enforces limit-based transfer controls, such as ensuring the maximum number of holders or specific jurisdictional limits have not been exceeded. HypershareRegistry manages frozen tokens and wallets, and ensures that tokens are not transferred in non-divisible quantities or while paused .

### HypershareClaims
The HypershareClaims contract verifies that the receiver is either whitelisted and therefore exempt, or that the receiver has the appropriate claims to receive equity tokens. Instead of manually checking each interaction, the compliance contracts can be used to define and verify the essential properties of an account on-chain.

## Structure
The metadata records the key terms contained within the agreement in a machine-readable format.
The markdown records and captures the terms of the legal agreement in a human-readable format.
A smart contract enforces the relevant terms from the agreement on-chain.    

## Metadata

Hypershare uses a metadata model to aggregate the key terms of an agreement in a machine-readable format. Providing metadata on the underlying agreement enables greatly enhanced flexibility. For Hypershare, metadata is embedded directly in the token URI and structured in much the same way as metadata for an NFT. This aggregates key information from the agreement and provides a way for agreement data to be indexed and utilised by third parties.

    {
   	 "name": "Acme Ordinary Shares",
   	 "symbol": "ACME",
   	 "description": "Acme limited fully paid ordinary shares",
   	 "image": "ipfs:./QmW78TSUVA2343HCADk..../acmelogo.png",
   	 "agreement": "ipfs:./QmWS1VAdMD353A6SDk..../agreement.md"
   	 "agreementMetadata": {
   		 "$class": "org.hypersurface.tokenHolderAgreement.tokenHolderClause",
   		 "companyName": "ACME LIMITED",
   		 "companyNumber": "123456789",
   		 "companyIdentity": "acme.hypersurface.finance",
   		 "acceptedCountries": ["United Kingdom", "France", "Germany", "Sweden"],
   		 "signatureRequired": "True",
   		 "asset": {
   			 "$class": "org.hypersurface.assets.ordinaryShare",
   			 "shareFullyPaid": "True",
   			 "shareDivisible": "False",
   			 "shareTransferLimit": "True",
   			 "shareHolderLimit": "True",
   			 "clauseId": "N234JKHKNM-8791-2146-AD7Y-8YRjgK24121L4K"
   		 },
   		 "clauseId": "45KNKL43NL-8932-5434-231n-083kjn21kjn3w"
   	 }
    }

## Encoding

The process of creating and encoding legal smart contracts generates a secure link between objects. By creating a bidirectional connection that maps the intended relationship between the legal contract and the smart contract in the token URI, the process creates a cryptographically secure dual integration that ensures that information recorded off-chain is tamperproof.

In this example, we use a token holders agreement. The steps to create a smart legal contract are as follows:
    1. The user inputs data via the web application.
    2. This data is then used to create a structured metadata model using JSON.
    3. A new token is created in the Hypershare token contract with a unique identifier.
    4. The metadata model is updated with a reference to the unique identifier of the token.
    5. The compliance contract is updated with the terms of the agreement to be enforced on-chain from the structured data model, referencing the token identifier.
    6. The metadata is used to render the legal agreement in Markdown.
    7. The legal Markdown file is uploaded to IPFS.
    8. The metadata is updated with the legal agreement IPFS URI.
    9. The metadata JSON file is uploaded to IPFS.
    10. The Hypershare token is updated with the structured metadata model IPFS URI.
