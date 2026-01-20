const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Governance Proposals", function () {
  it("Should allow proposal creation with stake", async function () {
    const [owner] = await ethers.getSigners();
    const DAO = await ethers.getContractFactory("DAOGovernance");
    const dao = await DAO.deploy();
    await dao.waitForDeployment();

    await dao.deposit({ value: ethers.parseEther("5") });

    await expect(
      dao.propose(
        0,
        owner.address,
        ethers.parseEther("1"),
        "Test proposal"
      )
    ).to.not.be.reverted;
  });
});
