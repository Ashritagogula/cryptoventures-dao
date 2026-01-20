const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Treasury", function () {
  it("Should accept ETH deposits", async function () {
    const DAO = await ethers.getContractFactory("DAOGovernance");
    const dao = await DAO.deploy();
    await dao.waitForDeployment();

    await expect(
      dao.deposit({ value: ethers.parseEther("2") })
    ).to.not.be.reverted;
  });
});
