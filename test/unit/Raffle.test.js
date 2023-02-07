const { getNamedAccounts, deployments, network } = require("hardhat");
const {
  developmentChains,
  networkConfig,
} = require("../../helper-hardhat-config");
const assert = require("chai").assert;
const expect = require("chai").expect;

!developmentChains.includes(network.name)
  ? describe.skip
  : describe("Raffle", async function () {
      let raffle, vrfCoordinatorV2Mock, raffleEntranceFee, deployer, interval;

      const chainId = network.config.chainId;

      beforeEach(async function () {
        deployer = (await getNamedAccounts()).deployer;
        await deployments.fixture(["all"]);
        raffle = await ethers.getContract("Raffle", deployer);

        vrfCoordinatorV2Mock = ethers.getContract(
          "VRFCoordinatorV2MOck",
          deployer
        );
        raffleEntranceFee = await raffle.getEntranceFee();
        interval = await raffle.getInterval
      });

      describe("constructor", async function () {
        it(" it initializes the raffle correctly", async function () {
          // idealy we make our tests have just one assert per it
          const raffleState = await raffle.getRaffleState();
          const interval = await raffle.getInterval();
          assert.equal(raffleState.toString(), "0");
          assert.equal(interval.toString(), networkConfig[chainId]["interval"]);
        });
      });
      describe("enterRaffle", async function () {
        // it("reverts when you don't pay enough", async function () {
        //   await expect(raffle.enterRaffle()).to.be.revertedWith(
        //     "Raffle__NotEnoughETHEntered"
        //   );
        // });

        it("records players when they enter", async function () {
          await raffle.enterRaffle({ value: raffleEntranceFee });
          const playerFromContract = await raffle.getPlayer(0);
          assert.equal(playerFromContract.deployer);
        });
        // it("emits events on enter", async function () {
        //   await expect(
        //     raffle.enterRaffle({ value: raffleEntranceFee })
        //   ).to.emit("raffle", "RaffleEnter");
        // });
        // it("doesn't allow entrance when raffle is calculating", async function () {
        //   await raffle.enterRaffle({ value: raffleEntranceFee });
        //   await network.provider.send("evm_increasetime", [interval.toNumber() + 1])
        //   await network.provider.send("evm_mine", [])
        //   //pretend to be a chinlink keeper
        //   await raffle.performUpKeep([])
        //   await expect(raffle.enterRaffle({ value: raffleEntranceFee})).to.be.revertedWith(
        //     "Raffle__NotOpen"
        //   )
        // });
      });
    });
