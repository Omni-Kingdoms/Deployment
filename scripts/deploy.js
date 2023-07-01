/* global ethers */
/* eslint prefer-const: "off" */
const hre = require("hardhat");
const { getSelectors, FacetCutAction } = require("./libraries/diamond.js");
// console.log("this is env", process.env.WALLET);

async function deployDiamond() {
  const accounts = await ethers.getSigners();
  const contractOwner = accounts[0];

  // Deploy DiamondInit
  // DiamondInit provides a function that is called when the diamond is upgraded or deployed to initialize state variables
  // Read about how the diamondCut function works in the EIP2535 Diamonds standard
  // const DiamondInit = await ethers.getContractFactory("DiamondInit");
  // const diamondInit = await DiamondInit.deploy();

  const diamondInit = await hre.ethers.deployContract("DiamondInit", {
    maxPriorityFeePerGas: 2000000000, maxFeePerGas: 2500000001,
  });
  const tx = await diamondInit.waitForDeployment();

  console.log("DiamondInit deployed:", diamondInit.target);

  // Deploy facets and set the `facetCuts` variable
  const FacetNames = [
    "DiamondCutFacet",
    "DiamondLoupeFacet",
    "OwnershipFacet",
    "ERC721Facet",
    "PlayerFacet",
    // "QuestFacet",
    // 'CraftFacet',
    // 'TrainFacet',
    // 'EquipFacet',
    //'ArenaFacet'
    // 'ExchangeFacet',
    // 'ScriptFacet',
    //'TreasureDropFacet'
  ];
  // The `facetCuts` variable is the FacetCut[] that contains the functions to add during diamond deployment
  const facetCuts = [];
  for (const FacetName of FacetNames) {
    // const Facet = await ethers.getContractFactory(FacetName);
    // const facet = await Facet.deploy();
    const facet = await hre.ethers.deployContract(FacetName);
    const tx = await facet.waitForDeployment();

    console.log(`${FacetName} deployed: ${facet.target}`);
    facetCuts.push({
      facetAddress: facet.target,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet),
    });

    await verifyContract(facet, FacetName);
  }
  //console.log("Facet Cuts = ", facetCuts);

  // Creating a function call
  // This call gets executed during deployment and can also be executed in upgrades
  // It is executed with delegatecall on the DiamondInit address.
  let functionCall = diamondInit.interface.encodeFunctionData("init");
  console.log("function call", functionCall);

  // Setting arguments that will be used in the diamond constructor
  const diamondArgs = {
    owner: contractOwner.address,
    init: diamondInit.target,
    initCalldata: functionCall,
  };
  // deploy Diamond
  // const Diamond = await ethers.getContractFactory("Diamond");
  // const diamond = await Diamond.deploy(facetCuts, diamondArgs);
  const diamond = await hre.ethers.deployContract("Diamond", [
    facetCuts,
    diamondArgs,
  ]);
  await diamond.waitForDeployment();
  console.log("Diamond deployed:", diamond.target);

  // await verifyDiamond(diamond, facetCuts, diamondArgs);

  // returning the address of the diamond
  return diamond.target;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployDiamond()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

exports.deployDiamond = deployDiamond;

async function verifyContract(diamond, FacetName, constructorArguments = []) {
  const liveNetworks = ["mainnet", "goerli", "mumbai", "scroll"];
  if (!liveNetworks.includes(hre.network.name)) {
    return; // Don't verify on test networks
  }

  try {
    console.log("Waiting for 10 blocks to be mined...");
    await diamond.deployTransaction.wait(10);
    console.log("Running verification");
    await hre.run("verify:verify", {
      address: diamond.target,
      contract: `contracts/facets/${FacetName}.sol:${FacetName}`,
      network: hardhatArguments.network,
      arguments: constructorArguments ? constructorArguments : [],
    });
  } catch (e) {
    console.log("Verification failed: ", JSON.stringify(e, null, 2));
  }

  // hre.run('verify:verify', {
  //   address: diamond.target,
  //   constructorArguments
  // })
}

async function verifyDiamond(diamond, facetCuts, diamondArgs) {
  const liveNetworks = ["mainnet", "goerli", "mumbai", "scroll"];
  if (!liveNetworks.includes(hre.network.name)) {
    return; // Don't verify on test networks
  }

  try {
    console.log("Waiting for 10 blocks to be mined...");
    console.log("---------------");
    console.log("Facet cuts = ", facetCuts);
    console.log("Diamond Args = ", diamondArgs);
    console.log("---------------");
    await diamond.deployTransaction.wait(10);
    console.log("Running verification");
    await hre.run("verify:verify", {
      address: diamond.target,
      contract: "contracts/Diamond.sol:Diamond",
      network: hardhatArguments.network,
      arguments: [facetCuts, diamondArgs],
    });
  } catch (e) {
    console.log("Verification failed: ", JSON.stringify(e, null, 2));
  }

  // hre.run('verify:verify', {
  //   address: diamond.target,
  //   constructorArguments
  // })
}
