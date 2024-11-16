// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity >=0.8.13 <0.9.0;

import "fhevm/lib/TFHE.sol";
import "fhevm/gateway/GatewayCaller.sol";

contract JoyConnectVoterSample is GatewayCaller {
    // Mappings for storing encrypted vote counts, choices, and voting status
    mapping(address => euint64) internal encryptedVoteCounts;
    mapping(address => ebool) internal encryptedVoteChoices;
    mapping(address => bool) internal hasVoted;

    // Encrypted tallies for "in favor" and "against" votes
    euint64 private inFavorCountEncrypted;
    euint64 private againstCountEncrypted;

    // Owner and plaintext tallies for revealed results
    address public owner;
    uint64 public inFavorCount;
    uint64 public againstCount;

    // Constructor sets up initial values and permissions for vote tallies
    constructor() {
        // TEST
        // euint64 a = TFHE.asEuint64(0);
        // TFHE.allow(a, address(this));

        inFavorCountEncrypted = TFHE.asEuint64(0);
        againstCountEncrypted = TFHE.asEuint64(0);

        // Allow the contract to manage these encrypted counts
        TFHE.allow(inFavorCountEncrypted, address(this));
        TFHE.allow(againstCountEncrypted, address(this));

        inFavorCount = 0;
        againstCount = 0;
        owner = msg.sender;
    }

    // Modifier to restrict functions to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    /**
     * @notice Casts a vote with a given encrypted vote count and choice
     * @param encryptedVoteCount The encrypted voting power of the user
     * @param encryptedChoice Encrypted choice where 0 = against, 1 = in favor
     * @param inputProof Proof for decrypting inputs
     */
    function castEncryptedVote(einput encryptedVoteCount, einput encryptedChoice, bytes calldata inputProof) public {
        // Form the encrypted choice (0 or 1) for vote type
        euint8 userChoice = TFHE.asEuint8(encryptedChoice, inputProof);

        // Determine the vote type as a boolean: true = in favor, false = against
        ebool voteChoice = TFHE.eq(TFHE.asEuint8(1), userChoice);

        // Form the vote power
        euint64 votePower = TFHE.asEuint64(encryptedVoteCount, inputProof);

        // Update or initialize the encrypted vote count for the sender
        if (TFHE.isInitialized(encryptedVoteCounts[msg.sender])) {
            TFHE.allow(encryptedVoteCounts[msg.sender], address(this));
            encryptedVoteCounts[msg.sender] = TFHE.add(encryptedVoteCounts[msg.sender], votePower);
        } else {
            encryptedVoteCounts[msg.sender] = votePower;
        }

        // If already initialized, allow updating the global state variable and assign value; otherwise, assign directly
        if (TFHE.isInitialized(encryptedVoteChoices[msg.sender])) {
            TFHE.allow(encryptedVoteCounts[msg.sender], address(this));
            encryptedVoteChoices[msg.sender] = voteChoice;
        } else {
            encryptedVoteChoices[msg.sender] = voteChoice;
        }

        // Initialize local variables to avoid issues with uninitialized handles
        euint64 inFavorCountToCast = TFHE.asEuint64(0);
        euint64 againstCountToCast = TFHE.asEuint64(0);

        // Conditional assignment based on vote choice
        inFavorCountToCast = TFHE.select(
            voteChoice,
            votePower, // Set vote power for in-favor count if vote choice is true
            TFHE.asEuint64(0) // Otherwise, set to 0
        );

        againstCountToCast = TFHE.select(
            voteChoice,
            TFHE.asEuint64(0), // Set to 0 if vote choice is true
            votePower // Set vote power for against count if vote choice is false
        );

        // Add the computed vote powers to the encrypted tallies
        againstCountEncrypted = TFHE.add(againstCountEncrypted, againstCountToCast);
        inFavorCountEncrypted = TFHE.add(inFavorCountEncrypted, inFavorCountToCast);

        // Allow both the contract and owner to access these encrypted tallies in the future
        TFHE.allow(againstCountEncrypted, address(this));
        TFHE.allow(againstCountEncrypted, owner);
        TFHE.allow(inFavorCountEncrypted, address(this));
        TFHE.allow(inFavorCountEncrypted, owner);

        // Allow the user to view their vote choice and vote count in the future
        TFHE.allow(encryptedVoteChoices[msg.sender], address(this));
        TFHE.allow(encryptedVoteChoices[msg.sender], msg.sender);
        TFHE.allow(encryptedVoteCounts[msg.sender], address(this));
        TFHE.allow(encryptedVoteCounts[msg.sender], msg.sender);
    }

    /**
     * @notice Allows the owner to reveal the final result by decrypting tallies
     */
    function revealVotingResults() public onlyOwner {
        // Retrieve encrypted tallies
        euint64 totalInFavorCount = inFavorCountEncrypted;
        euint64 totalAgainstCount = againstCountEncrypted;

        // Grant the contract permission to handle encrypted tallies
        TFHE.allow(totalInFavorCount, address(this));
        TFHE.allow(totalAgainstCount, address(this));

        // Request decryption of the final vote tallies
        uint256[] memory cts = new uint256[](2);
        cts[0] = Gateway.toUint256(totalInFavorCount);
        cts[1] = Gateway.toUint256(totalAgainstCount);

        Gateway.requestDecryption(cts, this.decryptionCallback.selector, 0, block.timestamp + 100, false);
    }

    /**
     * @notice Callback function to handle decrypted results from the gateway
     * @param totalFavourCountDecrypted Decrypted in-favor vote count
     * @param totalAgainstCountDecrypted Decrypted against vote count
     * @return True if the callback is successful
     */
    function decryptionCallback(
        uint256 /*requestID*/,
        uint64 totalFavourCountDecrypted,
        uint64 totalAgainstCountDecrypted
    ) public onlyGateway returns (bool) {
        // Update plaintext tallies with decrypted values
        inFavorCount = totalFavourCountDecrypted;
        againstCount = totalAgainstCountDecrypted;
        return true;
    }

    /**
     * @notice Allows a user to view their own encrypted vote count
     * @return The encrypted vote count of the sender
     */
    function getOwnEncryptedVoteCount() public view returns (euint64) {
        return encryptedVoteCounts[msg.sender];
    }

    /**
     * @notice Allows a user to view their own encrypted vote choice
     * @return The encrypted vote choice of the sender
     */
    function getOwnEncryptedVoteChoice() public view returns (ebool) {
        return encryptedVoteChoices[msg.sender];
    }

    /**
     * @notice View the total encrypted count of in-favor votes
     * @return The encrypted in-favor vote count
     */
    function getEncryptedInFavorVoteCount() public view returns (euint64) {
        return inFavorCountEncrypted;
    }

    /**
     * @notice View the total encrypted count of against votes
     * @return The encrypted against vote count
     */
    function getEncryptedAgainstVoteCount() public view returns (euint64) {
        return againstCountEncrypted;
    }
}
