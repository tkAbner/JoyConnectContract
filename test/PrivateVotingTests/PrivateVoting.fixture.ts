
import { ethers } from "hardhat";

import type { JoyConnectVoterSample } from "../../types";
import { getSigners } from "../signers";

export async function deployVotingFixture(): Promise<JoyConnectVoterSample> {
  const signers = await getSigners();

  const contractFactory = await ethers.getContractFactory("JoyConnectVoterSample");
  const contract = await contractFactory.connect(signers.alice).deploy();
  await contract.waitForDeployment();
  console.log("JoyConnectVoter Contract Address is:", await contract.getAddress());

  return contract;
}