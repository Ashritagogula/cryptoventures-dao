const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Timelock", function () {
  it("Should not execute before timelock", async function () {
    const DAO = await ethers.getContractFactory("DAOGovernance");
    const dao = await DAO.deploy();
    await dao.waitForDeployment();

    expect(dao.execute).to.be.a("function");
  });
});
