/* global ethers */
/* eslint prefer-const: "off" */
const hre = require("hardhat");
const { getSelectors, FacetCutAction } = require("./libraries/diamond.js");

async function getFacetAddress(FacetName) {
  // TODO - Replace the addresses of the appropriate facets 
  switch (FacetName){
    case "DiamondCutFacet":
      return "0x7C6A9fD301D2f5b0b3E1B6d3eF0bEaC5Bd6aF2B1";
    case "DiamondLoupeFacet":
      return "0x7C6A9fD301D2f5b0b3E1B6d3eF0bEaC5Bd6aF2B1";
    case "OwnershipFacet":
      return "0x7C6A9fD301D2f5b0b3E1B6d3eF0bEaC5Bd6aF2B1";
    case "ERC721Facet":
      return "0x7C6A9fD301D2f5b0b3E1B6d3eF0bEaC5Bd6aF2B1";
    case "PlayerFacet":
      return "0x7C6A9fD301D2f5b0b3E1B6d3eF0bEaC5Bd6aF2B1";
    case 'TrainFacet':
      return "0x7C6A9fD301D2f5b0b3E1B6d3eF0bEaC5Bd6aF2B1";
    case 'ArenaFacet':
      return "0x7C6A9fD301D2f5b0b3E1B6d3eF0bEaC5Bd6aF2B1";
    case 'ExchangeFacet':
      return "0x7C6A9fD301D2f5b0b3E1B6d3eF0bEaC5Bd6aF2B1";
    case 'PlayerDropFacet':
      return "0x7C6A9fD301D2f5b0b3E1B6d3eF0bEaC5Bd6aF2B1";
    default:
      return "0x00";
  }
}

async function deployDiamond() {
  const accounts = await ethers.getSigners();
  const contractOwner = accounts[0];

  const FacetNames = [
    "DiamondCutFacet",
    "DiamondLoupeFacet",
    "OwnershipFacet",
    "ERC721Facet",
    "PlayerFacet",
    //"QuestFacet",
    //"CraftFacet",
    'TrainFacet',
    //'EquipFacet',
    // 'ShopFacet',
    'ArenaFacet',
    'ExchangeFacet',
    // 'MonsterFacet',
    // 'TreasureFacet',
    'PlayerDropFacet',
    //'ScriptFacet',
    //'BridgeFacet',
    //'OmniFacet',
    //'TreasureDropFacet'
  ];

  // The `facetCuts` variable is the FacetCut[] that contains the functions to add during diamond deployment
  const facetCuts = [];
  for (const FacetName of FacetNames) {
    const Facet = await ethers.getContractFactory(FacetName);
    // Get the facet address
    const facetAddress = await getFacetAddress(FacetName);
    // Connect to this deployed facet
    const facet = await Facet.attach(facetAddress);
    facetCuts.push({
      facetAddress: facetAddress,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet),
    });

    await verifyContract(facet, FacetName);
  }

    console.log("Facet cuts = ", facetCuts);

  const DiamondInit = await ethers.getContractFactory("DiamondInit");
  // TODO - Replace the address of the deployed DiamondInit contract
  const diamondInit = await DiamondInit.attach("0x7C6A9fD301D2f5b0b3E1B6d3eF0bEaC5Bd6aF2B1");

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
  const Diamond = await ethers.getContractFactory("Diamond");
  // TODO - Replace the address of the deployed Diamond contract
  const diamond = await Diamond.attach("0x7C6A9fD301D2f5b0b3E1B6d3eF0bEaC5Bd6aF2B1");
  await verifyDiamond(diamond, facetCuts, diamondArgs);

  // returning the address of the diamond
  return diamond.address;
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
}

// exports.deployDiamond = deployDiamond;

async function verifyContract(diamond, FacetName, constructorArguments = []) {
  const liveNetworks = [
    "mainnet",
    "goerli",
    "mumbai",
    "scroll",
    "scroll_sepolia",
    "scroll_test",
    "arbitrumGoerli",
    "arbg",
    "fuji",
    "mantle"
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
}

async function verifyDiamond(diamond, facetCuts, diamondArgs) {
  const liveNetworks = ["mainnet", "goerli", "mumbai", "scroll, mantle, scroll_sepolia"];
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
