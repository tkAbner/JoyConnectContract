
import { ethers } from "hardhat";

import type { JoyConnectVoter } from "../../types";
import { getSigners } from "../signers";

export async function deployVotingFixture(): Promise<JoyConnectVoter> {
  const signers = await getSigners();

  const contractFactory = await ethers.getContractFactory("JoyConnectVoter");
  const contract = await contractFactory.connect(signers.alice).deploy();
  await contract.waitForDeployment();
  console.log("JoyConnectVoter Contract Address is:", await contract.getAddress());
  const initTx = await contract.init();
  const initHash = await initTx.wait();
  console.log("JoyConnectVoter Init Hash is:", initHash);

  return contract;
}