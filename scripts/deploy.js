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
  const DiamondInit = await ethers.getContractFactory("DiamondInit");
  const diamondInit = await DiamondInit.deploy();
  await diamondInit.deployed();
  console.log("DiamondInit deployed:", diamondInit.address);

  // Deploy facets and set the `facetCuts` variable
  console.log("");
  console.log("Deploying facets");
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
    const Facet = await ethers.getContractFactory(FacetName);
    const facet = await Facet.deploy();
    await facet.deployed();
    console.log(`${FacetName} deployed: ${facet.address}`);
    facetCuts.push({
      facetAddress: facet.address,
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
    init: diamondInit.address,
    initCalldata: functionCall,
  };
  // deploy Diamond
  console.log("Deploying Diamond now...");
  const Diamond = await ethers.getContractFactory("Diamond");
  const diamond = await Diamond.deploy(facetCuts, diamondArgs);
  await diamond.deployed();

  console.log();
  console.log("Diamond deployed:", diamond.address);

  // await verifyDiamond(diamond, facetCuts, diamondArgs);

  // returning the address of the diamond
  return diamond.address;
}

// /Helper function to verify contracts AFTER deploying them
async function prepDiamond() {
  const accounts = await ethers.getSigners();
  const contractOwner = accounts[0];

  const diamondInit = await ethers.getContractAt(
    "DiamondInit",
    "0x6b30c8493c4c2e627fc2a0810e8b5667740b487c"
  );
  console.log("DiamondInit deployed:", diamondInit.address);

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
  const FacetAddresses = [
    "0xCfd1BC8354ae6253164cFba0cc14f96CB3c33d70",
    "0x0B5fd09f3090afAB61c5973aAe5f9F6a93031B2f",
    "0xF84e1c9112751304202F3e8AcD2E3Ab94F5Cd3Bb",
    "0xFdBAF770A02B9bb66e29323F618abC280Fb41701",
    "0x759b62Eb3C6e96a3B781ee0C7E0eCAa8887dC5e6",
  ];
  // The `facetCuts` variable is the FacetCut[] that contains the functions to add during diamond deployment
  const facetCuts = [];
  let i = 0;
  for (const FacetName of FacetNames) {
    const facet = await ethers.getContractAt(FacetName, FacetAddresses[i]);
    console.log(`${FacetName} instance created: ${facet.address}`);
    facetCuts.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet),
    });
    i++;
  }
  console.log("Facet Cuts created ");

  // Creating a function call
  // This call gets executed during deployment and can also be executed in upgrades
  // It is executed with delegatecall on the DiamondInit address.
  let functionCall = diamondInit.interface.encodeFunctionData("init");
  console.log("function call", functionCall);

  // Setting arguments that will be used in the diamond constructor
  const diamondArgs = {
    owner: contractOwner.address,
    init: diamondInit.address,
    initCalldata: functionCall,
  };
  // deploy Diamond
  const diamond = await ethers.getContractAt(
    "Diamond",
    "0xD2A2d8665F166b47488aF100032A728FbB72b2af"
  );

  console.log();
  console.log("Diamond instance created:", diamond.address);

  await verifyDiamond(diamond, facetCuts, diamondArgs);

  // returning the address of the diamond
  return diamond.address;
}

async function prepVerification() {
  const accounts = await ethers.getSigners();
  const contractOwner = accounts[0];

  console.log("Deploying facets");
  const FacetNames = [
    // "DiamondCutFacet",
    // "DiamondLoupeFacet",
    // "OwnershipFacet",
    // "ERC721Facet",
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
  const FacetAddresses = [
    // "0xCfd1BC8354ae6253164cFba0cc14f96CB3c33d70",
    // "0x0B5fd09f3090afAB61c5973aAe5f9F6a93031B2f",
    // "0xF84e1c9112751304202F3e8AcD2E3Ab94F5Cd3Bb",
    // "0xFdBAF770A02B9bb66e29323F618abC280Fb41701",
    "0x759b62Eb3C6e96a3B781ee0C7E0eCAa8887dC5e6",
  ];
  // The `facetCuts` variable is the FacetCut[] that contains the functions to add during diamond deployment
  const facetCuts = [];
  let i = 0;
  for (const FacetName of FacetNames) {
    const facet = await ethers.getContractAt(FacetName, FacetAddresses[i]);
    console.log(`${FacetName} instance created: ${facet.address}`);
    facetCuts.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet),
    });

    await verifyContract(facet, FacetName);
    i++;
  }
  console.log("Facet Cuts = ", facetCuts);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  // === This is for deploying a new diamond ===
  deployDiamond()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
  // === This is for preparing the facets for verification ===
  // prepVerification()
  //   .then(() => process.exit(0))
  //   .catch((error) => console.error(error));
}

// exports.deployDiamond = deployDiamond;

async function verifyContract(diamond, FacetName, constructorArguments = []) {
  const liveNetworks = [
    "mainnet",
    "goerli",
    "mumbai",
    "scroll",
    "arbitrumGoerli",
    "fuji",
  ];
  if (!liveNetworks.includes(hre.network.name)) {
    return; // Don't verify on test networks
  }

  try {
    console.log("Waiting for 10 blocks to be mined...");
    await diamond.deployTransaction.wait(10);
    console.log("Running verification");
    await hre.run("verify:verify", {
      address: diamond.address,
      contract: `contracts/facets/${FacetName}.sol:${FacetName}`,
      network: hardhatArguments.network,
      arguments: constructorArguments ? constructorArguments : [],
    });
  } catch (e) {
    console.log("Verification failed: ", JSON.stringify(e, null, 2));
    console.log(e);
  }

  // hre.run('verify:verify', {
  //   address: diamond.address,
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
    // await diamond.deployTransaction.wait(10);
    console.log("Running verification");
    await hre.run("verify:verify", {
      address: diamond.address,
      contract: "contracts/Diamond.sol:Diamond",
      network: hardhatArguments.network,
      arguments: [facetCuts, diamondArgs],
    });
  } catch (e) {
    console.log("Verification failed: ", JSON.stringify(e, null, 2));
  }

  // hre.run('verify:verify', {
  //   address: diamond.address,
  //   constructorArguments
  // })
}
