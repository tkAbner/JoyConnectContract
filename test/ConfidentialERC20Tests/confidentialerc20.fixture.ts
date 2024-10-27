import { ethers } from "hardhat";

import type { EncryptedERC20 } from "../../types";
import { getSigners } from "../signers";

export async function deployConfidentialERC20Fixture(): Promise<EncryptedERC20> {
  const signers = await getSigners();

  const contractFactory = await ethers.getContractFactory("EncryptedERC20");
  const contract = await contractFactory.connect(signers.alice).deploy();
  await contract.waitForDeployment();
  console.log("Encrypted ERC20 Contract Address is:", await contract.getAddress());

  return contract;
}
