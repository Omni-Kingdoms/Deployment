const { getSelectors, FacetCutAction } = require('./libraries/diamond.js');
const hre = require('hardhat');

const upgradeExample = async () => {

  const FacetName = "BridgeFacet"
    const Facet = await ethers.getContractFactory(FacetName)
    const facet = await Facet.deploy()
    await facet.deployed()
    console.log(`${FacetName} deployed: ${facet.address}`);

    //await verifyContract(facet, FacetName);

    //const diamondAddress = "0x55Fd95F322ED24705441806b73dD969558f5E9E5"; //current v3 mantletest
    //const diamondAddress = "0xC54561B8D106A9801a19c60473E50359F5fc2cd3"; //current v3 omni
    //const diamondAddress = "0xE62a60247D0b9c1D09193b0F60875bc49878f5DF"; //current v3 scroll sepolia
    //const diamondAddress = "0xba88AA97A4D6ca616677F74cc5d065135865896A"; //current v3 taiko_testnet
    //const diamondAddress = "0x1b0210C5876202de3f41B1931efafd39AEd269Bb"; //current v3 opbnb
    //const diamondAddress = "0x0A31e14967aA2CFD76DB8eF599e4eb032544e8AB"; //current v3 opg
    const diamondAddress = "0x9d23A355a99BCe2926DcF698e1A7C9Bb4f1Bba43"; //current v3 arbg


    const newFacetAddress = facet.address;

    const diamondCutFacet = await ethers.getContractAt(
        "DiamondCutFacet",
        diamondAddress
    );

    const NewFacet = await ethers.getContractFactory(FacetName);
    const selectorsToAdd = getSelectors(NewFacet);

    const tx = await diamondCutFacet.diamondCut(
        [
        {
            facetAddress: newFacetAddress,
            action: FacetCutAction.Add,
            functionSelectors: selectorsToAdd,
        },
        ],
        ethers.constants.AddressZero,
        "0x",
        { gasLimit: 800000 }
    );

    const receipt = await tx.wait();
    if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`);
    } else {
        console.log("Diamond upgrade success");
    }
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
upgradeExample()
    .then(() => process.exit(0))
    .catch((error) => {
    console.error(error);
    process.exit(1);
    });
}


// async function verifyContract (diamond, FacetName, constructorArguments = []) {
//     // const liveNetworks = ['mainnet', 'goerli', 'mumbai', 'scroll'];
//     // if (!liveNetworks.includes(hre.network.name)) {
//     //   return; // Don't verify on test networks
//     // }
  
//     try {
//       console.log("Waiting for 10 blocks to be mined...");
//       //await diamond.deployTransaction.wait(10);
//       console.log("Running verification");
//       await hre.run("verify:verify", {
//         address: diamond.address,
//         contract: `contracts/facets/${FacetName}.sol:${FacetName}`,
//         network: hardhatArguments.network,
//         arguments: constructorArguments ? constructorArguments : [],
//       });
//     } catch (e) {
//       console.log("Verification failed: ", JSON.stringify(e, null, 2));
//     }    
// }

async function verifyContract(diamond, FacetName, constructorArguments = []) {
    const liveNetworks = [
      "mainnet",
      "goerli",
      "mumbai",
      "scroll",
      "arbitrumGoerli",
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