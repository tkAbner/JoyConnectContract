/* eslint-disable @typescript-eslint/no-explicit-any */
import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { ConfidentialERC20, JoyConnectVoter } from "../types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  // const deployed = await deploy("ConfidentialERC20", {
  //   from: deployer,
  //   log: true,
  // });

  // const erc20 = (await (await hre.ethers.getContractFactory("ConfidentialERC20")).attach(deployed.address)) as ConfidentialERC20;
  // console.log(`ConfidentialToken contract deployed at: ${deployed.address}`);
  // try {
  //   const mintTx = await erc20.mint(1000000000);
  //   const mintHash = await mintTx.wait();
    
  //   console.log(`Minted 1000000000 tokens: ${mintHash}`);
  // } catch (e) {
  //   const error = e as any;
  //   console.log({reason: error.data})
    
  // }

  const deployed2 = await deploy("JoyConnectVoter", {
    from: deployer,
    log: true,
  });
  console.log(`JoyConnectVoter contract deployed at: ${deployed2.address}`);
  const voter = (await (await hre.ethers.getContractFactory("JoyConnectVoter")).attach(deployed2.address)) as JoyConnectVoter;
  console.log({
    voter,
  })

  const tx = await voter.init();
  const hash = await tx.wait();
  console.log({
    hash
  })

  // const deployed3 = await deploy("JoyConnectVoterSample", {
  //   from: deployer,
  //   log: true,
  //   gasLimit: 10000000,
  // });
  // console.log(`JoyConnectVoterSample contract deployed at: ${deployed3.address}`);
};

export default func;
func.id = "deploy_confidentialERC20";
func.tags = ["ConfidentialToken"];
