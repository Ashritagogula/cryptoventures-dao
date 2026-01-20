const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Voting", function () {
  it("Should allow voting on a proposal", async function () {
    const [owner, voter] = await ethers.getSigners();
    const DAO = await ethers.getContractFactory("DAOGovernance");
    const dao = await DAO.deploy();
    await dao.waitForDeployment();

    await dao.deposit({ value: ethers.parseEther("5") });
    await dao.connect(voter).deposit({ value: ethers.parseEther("5") });

    await dao.propose(
      0,
      owner.address,
      ethers.parseEther("1"),
      "Vote test"
    );

    await expect(
      dao.connect(voter).castVote(1, 1)
    ).to.not.be.reverted;
  });
});
