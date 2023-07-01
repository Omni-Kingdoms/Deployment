/* global ethers */
/* eslint prefer-const: "off" */
const hre = require("hardhat");
const { getSelectors, FacetCutAction } = require("./libraries/diamond.js");
// console.log("this is env", process.env.WALLET);

async function deployTest() {
  let fee = await hre.ethers.provider.getFeeData();

  const accounts = await ethers.getSigners();
  const contractOwner = accounts[0];

  // Deploy DiamondInit
  // DiamondInit provides a function that is called when the diamond is upgraded or deployed to initialize state variables
  // Read about how the diamondCut function works in the EIP2535 Diamonds standard
  // const DiamondInit = await ethers.getContractFactory("DiamondInit");
  // const diamondInit = await DiamondInit.deploy();

  const test = await hre.ethers.deployContract("Test");
  const tx = await test.waitForDeployment();
  console.log(`🚀 Test deployed to ${test.target}`)
  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployTest()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

exports.test = deployTest;
