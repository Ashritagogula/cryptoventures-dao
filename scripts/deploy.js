const hre = require("hardhat");

async function main() {
  const [deployer, member1, member2, member3] = await hre.ethers.getSigners();

  console.log("Deploying contracts with:", deployer.address);

  const DAOGovernance = await hre.ethers.getContractFactory("DAOGovernance");
  const governance = await DAOGovernance.deploy();

  await governance.waitForDeployment();

  const address = await governance.getAddress();
  console.log("DAOGovernance deployed at:", address);

  // Seed treasury
  await governance.connect(member1).deposit({ value: hre.ethers.parseEther("10") });
  await governance.connect(member2).deposit({ value: hre.ethers.parseEther("20") });
  await governance.connect(member3).deposit({ value: hre.ethers.parseEther("30") });

  console.log("Seeded treasury with test deposits");

  // Create sample proposal
  await governance.connect(member1).propose(
    0,
    member2.address,
    hre.ethers.parseEther("1"),
    "Sample investment proposal"
  );

  console.log("Sample proposal created");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
