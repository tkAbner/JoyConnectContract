import { expect } from "chai";
// import { ethers } from "hardhat";
import { createInstances } from "../instance";
import { getSigners, initSigners } from "../signers";
import { deployVotingFixture } from "./JoyConnectVoter.fixture";

describe("Voting Contract Tests", function () {
  before(async function () {
    await initSigners();
    this.signers = await getSigners();
    this.instances = await createInstances(this.signers);
  });

  beforeEach(async function () {
    this.votingContract = await deployVotingFixture();
    this.contractAddress = await this.votingContract.getAddress();
  });

  describe("Should be able to vote and re-encrypt the values", function () {
    it("should be able to vote in favour and re-encrypt the values ", async function () {
      // const votingContract = this.votingContract.connect();

      const owner = await this.votingContract.owner();
      console.log({
        owner,
        signer: this.signers.alice.address,
      })

      const targetAddress = "0x0000000000000000000000000000000000000001"

      const input = this.instances.alice.createEncryptedInput(this.contractAddress, this.signers.alice.address);
      input.add64(1); // likes, like = 1, dislike = 0
      const encryptedVotingCount = input.encrypt();

      const voteTx = await this.votingContract.vote(
        targetAddress,
        encryptedVotingCount.handles[0],
        encryptedVotingCount.inputProof,
      );

      const receipt = await voteTx.wait();
      // expect(hash.status).is.not.null;
      console.log("hash : ", receipt.transactionHash);

      const eVote = await this.votingContract.getUserEncryptedVoteCount(targetAddress);
      console.log("eVote : ", eVote);

      const dVote = await this.votingContract.getDecryptedVoteCount(targetAddress);
      console.log(`dVote: ${dVote}`);


      // const { publicKey: alicePublicKey, privateKey: alicePrivateKey } = this.instances.alice.generateKeypair();

      // Prepare EIP-712 signature for Alice's re-encryption request
      // const eip712Message = this.instances.alice.createEIP712(alicePublicKey, this.contractAddress);
      // const aliceSignature = await this.signers.alice.signTypedData(
      //   eip712Message.domain,
      //   { Reencrypt: eip712Message.types.Reencrypt },
      //   eip712Message.message,
      // );


      // const eVoteDecrypt = await this.instances.alice.reencrypt(
      //   eVote,
      //   alicePrivateKey,
      //   alicePublicKey,
      //   aliceSignature.replace("0x", ""),
      //   this.contractAddress,
      //   this.signers.alice.address,
      // );
      // console.log("eVoteDecrypt", eVoteDecrypt);
      // return expect(1).to.be.equal(1);


      // 
      
      const revealTx = await this.votingContract.revealVotingResultForUser(targetAddress);
      const revealReceipt = await revealTx.wait();
      console.log("reveal hash : ", revealReceipt.transactionHash);

      console.log('delay....');
      await delay(1000 * 60);

      const eVote2 = await this.votingContract.getUserEncryptedVoteCount(targetAddress);
      console.log("eVote2 : ", eVote2);

      const dVote2 = await this.votingContract.getDecryptedVoteCount(targetAddress);
      console.log(`dVote2: ${dVote2}`);


      // expect(hash.status).is.not.null('Transaction failed');

      // const eboolVoteChoice = await this.votingContract.getOwnEncryptedVoteChoice();
      // const euint64VotePower = await this.votingContract.getOwnEncryptedVoteCount();
      // // Generate public-private keypair for Alice
      // const { publicKey: alicePublicKey, privateKey: alicePrivateKey } = this.instances.alice.generateKeypair();

      // // Prepare EIP-712 signature for Alice's re-encryption request
      // const eip712Message = this.instances.alice.createEIP712(alicePublicKey, this.contractAddress);
      // const aliceSignature = await this.signers.alice.signTypedData(
      //   eip712Message.domain,
      //   { Reencrypt: eip712Message.types.Reencrypt },
      //   eip712Message.message,
      // );

      // // Re-encrypt each random number and retrieve results
      // const voteChoice = await this.instances.alice.reencrypt(
      //   eboolVoteChoice,
      //   alicePrivateKey,
      //   alicePublicKey,
      //   aliceSignature.replace("0x", ""),
      //   this.contractAddress,
      //   this.signers.alice.address,
      // );

      // const votePower = await this.instances.alice.reencrypt(
      //   euint64VotePower,
      //   alicePrivateKey,
      //   alicePublicKey,
      //   aliceSignature.replace("0x", ""),
      //   this.contractAddress,
      //   this.signers.alice.address,
      // );

      // console.log("user voted for : ", voteChoice);
      // console.log("user vote power is : ", votePower);
    });
  });

  // describe("Should be able to vote ", function () {
  //   it("should be able to vote in favour ", async function () {
  //     const input = this.instances.alice.createEncryptedInput(this.contractAddress, this.signers.alice.address);
  //     input.add64(1000);
  //     input.add8(1);
  //     const encryptedVotingCountAndEncryptedChoice = input.encrypt();

  //     const voteTx = await this.votingContract.castEncryptedVote(
  //       encryptedVotingCountAndEncryptedChoice.handles[0],
  //       encryptedVotingCountAndEncryptedChoice.handles[1],
  //       encryptedVotingCountAndEncryptedChoice.inputProof,
  //     );

  //     await voteTx.wait();
  //   });

  //   it("should be able to vote against the proposal ", async function () {
  //     const input = this.instances.alice.createEncryptedInput(this.contractAddress, this.signers.alice.address);
  //     input.add64(1000);
  //     input.add8(0);
  //     const encryptedVotingCountAndEncryptedChoice = input.encrypt();

  //     const voteTx = await this.votingContract.castEncryptedVote(
  //       encryptedVotingCountAndEncryptedChoice.handles[0],
  //       encryptedVotingCountAndEncryptedChoice.handles[1],
  //       encryptedVotingCountAndEncryptedChoice.inputProof,
  //     );

  //     await voteTx.wait();
  //   });
  // });

});

function delay(time: number) {
  return new Promise((res) => {
    setTimeout(res, time);
  });
}